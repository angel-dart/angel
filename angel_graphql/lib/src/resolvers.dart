import 'package:angel_framework/angel_framework.dart';
import 'package:graphql_schema/graphql_schema.dart';

/// A GraphQL resolver that `index`es an Angel service.
///
/// The arguments passed to the resolver will be forwarded to service, and the
/// service will receive [Providers.graphql].
GraphQLFieldResolver<Value, Serialized>
    resolveViaServiceIndex<Value, Serialized>(Service service,
        {String idField: 'id'}) {
  return (_, arguments) async {
    var params = {'query': arguments, 'provider': Providers.graphql};

    return await service.index(params) as Value;
  };
}

/// A GraphQL resolver that `read`s a single value from an Angel service.
///
/// The arguments passed to the resolver will be forwarded to service, and the
/// service will receive [Providers.graphql].
GraphQLFieldResolver<Value, Serialized>
    resolveViaServiceRead<Value, Serialized>(Service service,
        {String idField: 'id'}) {
  return (_, arguments) async {
    var params = {'query': arguments, 'provider': Providers.graphql};
    var id = arguments.remove(idField);
    return await service.read(id, params) as Value;
  };
}
