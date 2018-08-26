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
typedef AngelDeserializer(x);

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

  Service service(String path, {Type type, AngelDeserializer deserializer});

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
abstract class Service {
  /// Fired on `indexed` events.
  Stream get onIndexed;

  /// Fired on `read` events.
  Stream get onRead;

  /// Fired on `created` events.
  Stream get onCreated;

  /// Fired on `modified` events.
  Stream get onModified;

  /// Fired on `updated` events.
  Stream get onUpdated;

  /// Fired on `removed` events.
  Stream get onRemoved;

  /// The Angel instance powering this service.
  Angel get app;

  Future close();

  /// Retrieves all resources.
  Future index([Map params]);

  /// Retrieves the desired resource.
  Future read(id, [Map params]);

  /// Creates a resource.
  Future create(data, [Map params]);

  /// Modifies a resource.
  Future modify(id, data, [Map params]);

  /// Overwrites a resource.
  Future update(id, data, [Map params]);

  /// Removes the given resource.
  Future remove(id, [Map params]);
}

/// A [List] that automatically updates itself whenever the referenced [service] fires an event.
class ServiceList extends DelegatingList {
  /// A field name used to compare [Map] by ID.
  final String idField;

  /// If `true` (default: `false`), then `index` events will be handled as a [Map] containing a `data` field.
  ///
  /// See https://github.com/angel-dart/paginate.
  final bool asPaginated;

  /// A function used to compare the ID's two items for equality.
  ///
  /// Defaults to comparing the [idField] of `Map` instances.
  final Equality _compare;

  final Service service;

  final StreamController<ServiceList> _onChange = new StreamController();
  final List<StreamSubscription> _subs = [];

  ServiceList(this.service,
      {this.idField, this.asPaginated: false, Equality compare})
      : _compare = compare ?? new EqualityBy((map) => map[idField ?? 'id']),
        super([]) {
    // Index
    _subs.add(service.onIndexed.listen((data) {
      var items = asPaginated == true ? data['data'] : data;
      this
        ..clear()
        ..addAll(items as Iterable);
      _onChange.add(this);
    }));

    // Created
    _subs.add(service.onCreated.listen((item) {
      add(item);
      _onChange.add(this);
    }));

    // Modified/Updated
    handleModified(item) {
      var indices = <int>[];

      for (int i = 0; i < length; i++) {
        if (_compare.equals(item, this[i])) indices.add(i);
      }

      if (indices.isNotEmpty) {
        for (var i in indices) this[i] = item;

        _onChange.add(this);
      }
    }

    _subs.addAll([
      service.onModified.listen(handleModified),
      service.onUpdated.listen(handleModified),
    ]);

    // Removed
    _subs.add(service.onRemoved.listen((item) {
      removeWhere((x) => _compare.equals(item, x));
      _onChange.add(this);
    }));
  }

  /// Fires whenever the underlying [service] fires a change event.
  Stream<ServiceList> get onChange => _onChange.stream;

  Future close() async {
    _onChange.close();
  }
}
