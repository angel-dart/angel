import 'dart:async';

import 'package:angel_framework/angel_framework.dart';
import 'package:angel_graphql/angel_graphql.dart';
import 'package:graphql_schema/graphql_schema.dart';
import 'package:graphql_server/graphql_server.dart';
import 'package:graphql_server/mirrors.dart';

import 'src/models/models.dart';

Future configureServer(Angel app) async {
  // Create standard Angel services. Note that these will also *automatically* be
  // exposed via a REST API as well.
  var droidService = mountService<Droid>(app, '/api/droids');
  var humansService = mountService<Human>(app, '/api/humans');
  var starshipService = mountService<Starship>(app, '/api/starships');

  // Create the GraphQL schema.
  // This code uses dart:mirrors to easily create GraphQL types from Dart PODO's.
  //var droidType = convertDartType(Droid);
  //var episodeType = convertDartType(Episode);
  var humanType = convertDartType(Human);

  // Create the query type.
  //
  // Use the `resolveViaServiceIndex` helper to load data directly from an
  // Angel service.
  var queryType = objectType('StarWarsQuery', fields: [
    field(
      'humans',
      type: listType(humanType.nonNullable()),
      resolve: resolveViaServiceIndex(humansService),
    ),
  ]);

  // Finally, create the schema.
  var schema = graphQLSchema(query: queryType);

  // Next, create a GraphQL object, which will be passed to `graphQLHttp`, and
  // used to mount a spec-compliant GraphQL endpoint on the server.
  var graphQL = new GraphQL(schema);

  // Mount the GraphQL endpoint.
  app.all('/graphql', graphQLHttp(graphQL));

  // In development, we'll want to mount GraphiQL, for easy management of the database.
  if (!app.isProduction) {
    app.get('/graphiql', graphiQL());
  }
}

Service mountService<T extends Model>(Angel app, String path) => app.use(
    path,
    new TypedService(new MapService(
        autoIdAndDateFields: false, autoSnakeCaseNames: false))) as Service;
