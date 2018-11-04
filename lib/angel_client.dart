/// Client library for the Angel framework.
library angel_client;

import 'dart:async';
import 'package:collection/collection.dart';
import 'dart:convert';
import 'package:http/src/response.dart' as http;
export 'package:angel_http_exception/angel_http_exception.dart';

/// A function that configures an [Angel] client in some way.
typedef Future AngelConfigurer(Angel app);

/// A function that deserializes data received from the server.
///
/// This is only really necessary in the browser, where `json_god`
/// doesn't work.
typedef T AngelDeserializer<T>(x);

/// Represents an Angel server that we are querying.
abstract class Angel {
  String authToken;
  String basePath;

  Angel(String this.basePath);

  /// Fired whenever a WebSocket is successfully authenticated.
  Stream<AngelAuthResult> get onAuthenticated;

  Future<AngelAuthResult> authenticate(
      {String type,
      credentials,
      String authEndpoint: '/auth',
      String reviveEndpoint: '/auth/token'});

  /// Opens the [url] in a new window, and  returns a [Stream] that will fire a JWT on successful authentication.
  Stream<String> authenticateViaPopup(String url, {String eventName: 'token'});

  Future close();

  /// Applies an [AngelConfigurer] to this instance.
  Future configure(AngelConfigurer configurer) async {
    await configurer(this);
  }

  /// Logs the current user out of the application.
  Future logout();

  Service<Id, Data> service<Id, Data>(String path,
      {Type type, AngelDeserializer<Data> deserializer});

  Future<http.Response> delete(String url, {Map<String, String> headers});

  Future<http.Response> get(String url, {Map<String, String> headers});

  Future<http.Response> head(String url, {Map<String, String> headers});

  Future<http.Response> patch(String url, {body, Map<String, String> headers});

  Future<http.Response> post(String url, {body, Map<String, String> headers});

  Future<http.Response> put(String url, {body, Map<String, String> headers});
}

/// Represents the result of authentication with an Angel server.
class AngelAuthResult {
  String _token;
  final Map<String, dynamic> data = {};
  String get token => _token;

  AngelAuthResult({String token, Map<String, dynamic> data: const {}}) {
    _token = token;
    this.data.addAll(data ?? {});
  }

  factory AngelAuthResult.fromMap(Map data) {
    final result = new AngelAuthResult();

    if (data is Map && data.containsKey('token') && data['token'] is String)
      result._token = data['token'].toString();

    if (data is Map)
      result.data.addAll((data['data'] as Map<String, dynamic>) ?? {});

    return result;
  }

  factory AngelAuthResult.fromJson(String s) =>
      new AngelAuthResult.fromMap(json.decode(s) as Map);

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

  ServiceList(this.service, {this.idField, Equality<Data> equality})
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
    _onChange.close();
  }
}
