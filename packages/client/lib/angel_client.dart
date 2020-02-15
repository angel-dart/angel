/// Client library for the Angel framework.
library angel_client;

import 'dart:async';
import 'package:collection/collection.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
export 'package:angel_http_exception/angel_http_exception.dart';
import 'package:meta/meta.dart';

/// A function that configures an [Angel] client in some way.
typedef FutureOr<void> AngelConfigurer(Angel app);

/// A function that deserializes data received from the server.
///
/// This is only really necessary in the browser, where `json_god`
/// doesn't work.
typedef T AngelDeserializer<T>(x);

/// Represents an Angel server that we are querying.
abstract class Angel extends http.BaseClient {
  /// A mutable member. When this is set, it holds a JSON Web Token
  /// that is automatically attached to every request sent.
  ///
  /// This is designed with `package:angel_auth` in mind.
  String authToken;

  /// The root URL at which the target server.
  final Uri baseUrl;

  Angel(baseUrl)
      : this.baseUrl = baseUrl is Uri ? baseUrl : Uri.parse(baseUrl.toString());

  /// Prefer to use [baseUrl] instead.
  @deprecated
  String get basePath => baseUrl.toString();

  /// Fired whenever a WebSocket is successfully authenticated.
  Stream<AngelAuthResult> get onAuthenticated;

  /// Authenticates against the server.
  ///
  /// This is designed with `package:angel_auth` in mind.
  ///
  /// The [type] is appended to the [authEndpoint], ex. `local` becomes `/auth/local`.
  ///
  /// The given [credentials] are sent to server as-is; the request body is sent as JSON.
  Future<AngelAuthResult> authenticate(
      {@required String type,
      credentials,
      String authEndpoint = '/auth',
      @deprecated String reviveEndpoint = '/auth/token'});

  /// Shorthand for authenticating via a JWT string.
  Future<AngelAuthResult> reviveJwt(String token,
      {String authEndpoint = '/auth'}) {
    return authenticate(
        type: 'token',
        credentials: {'token': token},
        authEndpoint: authEndpoint);
  }

  /// Opens the [url] in a new window, and  returns a [Stream] that will fire a JWT on successful authentication.
  Stream<String> authenticateViaPopup(String url, {String eventName = 'token'});

  /// Disposes of any outstanding resources.
  Future<void> close();

  /// Applies an [AngelConfigurer] to this instance.
  Future<void> configure(AngelConfigurer configurer) async {
    await configurer(this);
  }

  /// Logs the current user out of the application.
  FutureOr<void> logout();

  /// Creates a [Service] instance that queries a given path on the server.
  ///
  /// This expects that there is an Angel `Service` mounted on the server.
  ///
  /// In other words, all endpoints will return [Data], except for the root of
  /// [path], which returns a [List<Data>].
  ///
  /// You can pass a custom [deserializer], which is typically necessary in cases where
  /// `dart:mirrors` does not exist.
  Service<Id, Data> service<Id, Data>(String path,
      {@deprecated Type type, AngelDeserializer<Data> deserializer});

  @override
  Future<http.Response> delete(url, {Map<String, String> headers});

  @override
  Future<http.Response> get(url, {Map<String, String> headers});

  @override
  Future<http.Response> head(url, {Map<String, String> headers});

  @override
  Future<http.Response> patch(url,
      {body, Map<String, String> headers, Encoding encoding});

  @override
  Future<http.Response> post(url,
      {body, Map<String, String> headers, Encoding encoding});

  @override
  Future<http.Response> put(url,
      {body, Map<String, String> headers, Encoding encoding});
}

/// Represents the result of authentication with an Angel server.
class AngelAuthResult {
  String _token;
  final Map<String, dynamic> data = {};

  /// The JSON Web token that was sent with this response.
  String get token => _token;

  AngelAuthResult({String token, Map<String, dynamic> data = const {}}) {
    _token = token;
    this.data.addAll(data ?? {});
  }

  /// Attempts to deserialize a response from a [Map].
  factory AngelAuthResult.fromMap(Map data) {
    final result = new AngelAuthResult();

    if (data is Map && data.containsKey('token') && data['token'] is String)
      result._token = data['token'].toString();

    if (data is Map)
      result.data.addAll((data['data'] as Map<String, dynamic>) ?? {});

    if (result.token == null) {
      throw new FormatException(
          'The required "token" field was not present in the given data.');
    } else if (data['data'] is! Map) {
      throw new FormatException(
          'The required "data" field in the given data was not a map; instead, it was ${data['data']}.');
    }

    return result;
  }

  /// Attempts to deserialize a response from a [String].
  factory AngelAuthResult.fromJson(String s) =>
      new AngelAuthResult.fromMap(json.decode(s) as Map);

  /// Converts this instance into a JSON-friendly representation.
  Map<String, dynamic> toJson() {
    return {'token': token, 'data': data};
  }
}

/// Queries a service on an Angel server, with the same API.
abstract class Service<Id, Data> {
  /// Fired on `indexed` events.
  Stream<List<Data>> get onIndexed;

  /// Fired on `read` events.
  Stream<Data> get onRead;

  /// Fired on `created` events.
  Stream<Data> get onCreated;

  /// Fired on `modified` events.
  Stream<Data> get onModified;

  /// Fired on `updated` events.
  Stream<Data> get onUpdated;

  /// Fired on `removed` events.
  Stream<Data> get onRemoved;

  /// The Angel instance powering this service.
  Angel get app;

  Future close();

  /// Retrieves all resources.
  Future<List<Data>> index([Map<String, dynamic> params]);

  /// Retrieves the desired resource.
  Future<Data> read(Id id, [Map<String, dynamic> params]);

  /// Creates a resource.
  Future<Data> create(Data data, [Map<String, dynamic> params]);

  /// Modifies a resource.
  Future<Data> modify(Id id, Data data, [Map<String, dynamic> params]);

  /// Overwrites a resource.
  Future<Data> update(Id id, Data data, [Map<String, dynamic> params]);

  /// Removes the given resource.
  Future<Data> remove(Id id, [Map<String, dynamic> params]);

  /// Creates a [Service] that wraps over this one, and maps input and output using two converter functions.
  ///
  /// Handy utility for handling data in a type-safe manner.
  Service<Id, U> map<U>(U Function(Data) encoder, Data Function(U) decoder) {
    return new _MappedService(this, encoder, decoder);
  }
}

class _MappedService<Id, Data, U> extends Service<Id, U> {
  final Service<Id, Data> inner;
  final U Function(Data) encoder;
  final Data Function(U) decoder;

  _MappedService(this.inner, this.encoder, this.decoder);

  @override
  Angel get app => inner.app;

  @override
  Future close() => new Future.value();

  @override
  Future<U> create(U data, [Map<String, dynamic> params]) {
    return inner.create(decoder(data)).then(encoder);
  }

  @override
  Future<List<U>> index([Map<String, dynamic> params]) {
    return inner.index(params).then((l) => l.map(encoder).toList());
  }

  @override
  Future<U> modify(Id id, U data, [Map<String, dynamic> params]) {
    return inner.modify(id, decoder(data), params).then(encoder);
  }

  @override
  Stream<U> get onCreated => inner.onCreated.map(encoder);

  @override
  Stream<List<U>> get onIndexed =>
      inner.onIndexed.map((l) => l.map(encoder).toList());

  @override
  Stream<U> get onModified => inner.onModified.map(encoder);

  @override
  Stream<U> get onRead => inner.onRead.map(encoder);

  @override
  Stream<U> get onRemoved => inner.onRemoved.map(encoder);

  @override
  Stream<U> get onUpdated => inner.onUpdated.map(encoder);

  @override
  Future<U> read(Id id, [Map<String, dynamic> params]) {
    return inner.read(id, params).then(encoder);
  }

  @override
  Future<U> remove(Id id, [Map<String, dynamic> params]) {
    return inner.remove(id, params).then(encoder);
  }

  @override
  Future<U> update(Id id, U data, [Map<String, dynamic> params]) {
    return inner.update(id, decoder(data), params).then(encoder);
  }
}

/// A [List] that automatically updates itself whenever the referenced [service] fires an event.
class ServiceList<Id, Data> extends DelegatingList<Data> {
  /// A field name used to compare [Map] by ID.
  final String idField;

  /// A function used to compare the ID's two items for equality.
  ///
  /// Defaults to comparing the [idField] of `Map` instances.
  Equality<Data> get equality => _equality;

  Equality<Data> _equality;

  final Service<Id, Data> service;

  final StreamController<ServiceList<Id, Data>> _onChange =
      new StreamController();

  final List<StreamSubscription> _subs = [];

  ServiceList(this.service, {this.idField = 'id', Equality<Data> equality})
      : super([]) {
    _equality = equality;
    _equality ??= new EqualityBy<Data, Id>((map) {
      if (map is Map)
        return map[idField ?? 'id'] as Id;
      else
        throw new UnsupportedError(
            'ServiceList only knows how to find the id from a Map object. Provide a custom `Equality` in your call to the constructor.');
    });
    // Index
    _subs.add(service.onIndexed.where(_notNull).listen((data) {
      this
        ..clear()
        ..addAll(data);
      _onChange.add(this);
    }));

    // Created
    _subs.add(service.onCreated.where(_notNull).listen((item) {
      add(item);
      _onChange.add(this);
    }));

    // Modified/Updated
    handleModified(Data item) {
      var indices = <int>[];

      for (int i = 0; i < length; i++) {
        if (_equality.equals(item, this[i])) indices.add(i);
      }

      if (indices.isNotEmpty) {
        for (var i in indices) this[i] = item;

        _onChange.add(this);
      }
    }

    _subs.addAll([
      service.onModified.where(_notNull).listen(handleModified),
      service.onUpdated.where(_notNull).listen(handleModified),
    ]);

    // Removed
    _subs.add(service.onRemoved.where(_notNull).listen((item) {
      removeWhere((x) => _equality.equals(item, x));
      _onChange.add(this);
    }));
  }

  static bool _notNull(x) => x != null;

  /// Fires whenever the underlying [service] fires a change event.
  Stream<ServiceList<Id, Data>> get onChange => _onChange.stream;

  Future close() async {
    await _onChange.close();
  }
}
