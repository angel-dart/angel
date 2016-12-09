/// Client library for the Angel framework.
library angel_client;

import 'dart:async';
import 'dart:convert';
export 'package:angel_framework/src/http/angel_http_exception.dart';

/// A function that configures an [Angel] client in some way.
typedef Future AngelConfigurer(Angel app);

/// Represents an Angel server that we are querying.
abstract class Angel {
  String get authToken;
  String basePath;

  Angel(String this.basePath);

  Future<AngelAuthResult> authenticate(
      {String type,
      credentials,
      String authEndpoint: '/auth',
      String reviveEndpoint: '/auth/token'});

  /// Applies an [AngelConfigurer] to this instance.
  Future configure(AngelConfigurer configurer) async {
    await configurer(this);
  }

  Service service(Pattern path, {Type type});
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
      result._token = data['token'];

    if (data is Map) result.data.addAll(data['data'] ?? {});

    return result;
  }

  factory AngelAuthResult.fromJson(String json) =>
      new AngelAuthResult.fromMap(JSON.decode(json));

  Map<String, dynamic> toJson() {
    return {'token': token, 'data': data};
  }
}

/// Queries a service on an Angel server, with the same API.
abstract class Service {
  /// The Angel instance powering this service.
  Angel get app;

  /// Retrieves all resources.
  Future<List> index([Map params]);

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
