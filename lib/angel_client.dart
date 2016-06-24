/// Client library for the Angel framework.
library angel_client;

import 'dart:async';
export 'src/rest.dart';

/// Queries a service on an Angel server, with the same API.
abstract class Service {
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