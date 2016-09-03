/// Client library for the Angel framework.
library angel_client;

import 'dart:async';

/// A function that configures an [Angel] client in some way.
typedef Future AngelConfigurer(Angel app);

/// Represents an Angel server that we are querying.
abstract class Angel {
  String basePath;

  Angel(String this.basePath);

  /// Applies an [AngelConfigurer] to this instance.
  Future configure(AngelConfigurer configurer) async {
    await configurer(this);
  }

  Service service(Pattern path, {Type type});
}

/// Queries a service on an Angel server, with the same API.
abstract class Service {
  /// The Angel instance powering this service.
  Angel app;

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
