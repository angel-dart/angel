import 'package:angel_framework/angel_framework.dart';
import 'package:graphql_schema/graphql_schema.dart';

/// A GraphQL resolver that indexes an Angel service.
///
/// If [enableRead] is `true`, and the [idField] is present in the input,
/// a `read` will be performed, rather than an `index`.
///
/// The arguments passed to the resolver will be forwarded to service, and the
/// service will receive [Providers.graphql].
GraphQLFieldResolver<Value, Serialized> resolveFromService<Value, Serialized>(
    Service service,
    {String idField: 'id',
    bool enableRead: true}) {
  return (_, arguments) async {
    var params = {'query': arguments, 'provider': Providers.graphql};

    if (enableRead && arguments.containsKey(idField)) {
      var id = arguments.remove(idField);
      return await service.read(id, params) as Value;
    }

    return await service.index(params) as Value;
  };
}
