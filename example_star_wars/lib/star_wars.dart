import 'dart:async';
import 'dart:math';

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
  var rnd = new Random();

  // Create the GraphQL schema.
  // This code uses dart:mirrors to easily create GraphQL types from Dart PODO's.
  var droidType = convertDartClass(Droid);
  var episodeType = convertDartType(Episode);
  var humanType = convertDartClass(Human);
  var starshipType = convertDartType(Starship);
  var heroType = new GraphQLUnionType('Hero', [droidType, humanType]);

  // Create the query type.
  //
  // Use the `resolveViaServiceIndex` helper to load data directly from an
  // Angel service.
  var queryType = objectType(
    'StarWarsQuery',
    description: 'A long time ago, in a galaxy far, far away...',
    fields: [
      field(
        'droids',
        type: listType(droidType.nonNullable()),
        resolve: resolveViaServiceIndex(droidService),
      ),
      field(
        'humans',
        type: listType(humanType.nonNullable()),
        resolve: resolveViaServiceIndex(humansService),
      ),
      field(
        'starships',
        type: listType(starshipType.nonNullable()),
        resolve: resolveViaServiceIndex(starshipService),
      ),
      field(
        'hero',
        type: heroType,
        resolve: (_, args) async {
          var allHeroes = [];
          var allDroids = await droidService.index() as Iterable;
          var allHumans = await humansService.index() as Iterable;
          allHeroes..addAll(allDroids)..addAll(allHumans);

          // Ignore the annoying cast here, hopefully Dart 2 fixes cases like this
          allHeroes = allHeroes
              .where((m) =>
                  !args.containsKey('ep') ||
                  (m['appears_in'].contains(args['ep']) as bool))
              .toList();

          return allHeroes.isEmpty
              ? null
              : allHeroes[rnd.nextInt(allHeroes.length)];
        },
      ),
    ],
  );

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

  // Seed the database.
  var leia = await humansService.create({
    'name': 'Leia Organa',
    'appears_in': ['NEWHOPE', 'EMPIRE', 'JEDI'],
    'total_credits': 520,
  });

  var hanSolo = await humansService.create({
    'name': 'Han Solo',
    'appears_in': ['NEWHOPE', 'EMPIRE', 'JEDI'],
    'total_credits': 23,
    'friends': [leia],
  });

  var luke = await humansService.create({
    'name': 'Luke Skywalker',
    'appears_in': ['NEWHOPE', 'EMPIRE', 'JEDI'],
    'total_credits': 682,
    'friends': [leia, hanSolo],
  });
}

Service mountService<T extends Model>(Angel app, String path) =>
    app.use(path, new TypedService(new MapService())) as Service;
