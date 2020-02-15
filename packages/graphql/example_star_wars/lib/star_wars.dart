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
  var droidService = app.use('/api/droids', MapService());
  var humansService = app.use('/api/humans', MapService());
  var starshipService = app.use('/api/starships', MapService());
  var rnd = Random();

  // Create the GraphQL schema.
  // `package:graphql_generator` has generated schemas for some of our
  // classes.

  // A Hero can be either a Droid or Human; create a union type that represents this.
  var heroType = GraphQLUnionType('Hero', [droidGraphQLType, humanGraphQLType]);

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
        listOf(droidGraphQLType.nonNullable()),
        description: 'All droids in the known galaxy.',
        resolve: resolveViaServiceIndex(droidService),
      ),
      field(
        'humans',
        listOf(humanGraphQLType.nonNullable()),
        description: 'All humans in the known galaxy.',
        resolve: resolveViaServiceIndex(humansService),
      ),
      field(
        'starships',
        listOf(starshipGraphQLType.nonNullable()),
        description: 'All starships in the known galaxy.',
        resolve: resolveViaServiceIndex(starshipService),
      ),
      field(
        'hero',
        heroType,
        description:
            'Finds a random hero within the known galaxy, whether a Droid or Human.',
        inputs: [
          GraphQLFieldInput('ep', episodeGraphQLType),
        ],
        resolve: randomHeroResolver(droidService, humansService, rnd),
      ),
    ],
  );

  // Convert our object types to input objects, so that they can be passed to
  // mutations.
  var humanChangesType = humanGraphQLType.toInputObject('HumanChanges');

  // Create the mutation type.
  var mutationType = objectType(
    'StarWarsMutation',
    fields: [
      // We'll use the `modify_human` mutation to modify a human in the database.
      field(
        'modify_human',
        humanGraphQLType.nonNullable(),
        description: 'Modifies a human in the database.',
        inputs: [
          GraphQLFieldInput('id', graphQLId.nonNullable()),
          GraphQLFieldInput('data', humanChangesType.nonNullable()),
        ],
        resolve: resolveViaServiceModify(humansService),
      ),
    ],
  );

  // Finally, create the schema.
  var schema = graphQLSchema(
    queryType: queryType,
    mutationType: mutationType,
  );

  // Next, create a GraphQL object, which will be passed to `graphQLHttp`, and
  // used to mount a spec-compliant GraphQL endpoint on the server.
  //
  // The `mirrorsFieldResolver` is unnecessary in this case, because we are using
  // `Map`s only, but if our services returned concrete Dart objects, we'd need
  // this to allow GraphQL to read field values.
  var graphQL = GraphQL(schema, defaultFieldResolver: mirrorsFieldResolver);

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

  var lando = await humansService.create({
    'name': 'Lando Calrissian',
    'appears_in': ['EMPIRE', 'JEDI'],
    'total_credits': 525430,
  });

  var hanSolo = await humansService.create({
    'name': 'Han Solo',
    'appears_in': ['NEWHOPE', 'EMPIRE', 'JEDI'],
    'total_credits': 23,
    'friends': [leia, lando],
  });

  // Luke, of course.
  await humansService.create({
    'name': 'Luke Skywalker',
    'appears_in': ['NEWHOPE', 'EMPIRE', 'JEDI'],
    'total_credits': 682,
    'friends': [leia, hanSolo, lando],
  });
}

GraphQLFieldResolver randomHeroResolver(
    Service droidService, Service humansService, Random rnd) {
  return (_, args) async {
    var allHeroes = [];
    var allDroids = await droidService.index();
    var allHumans = await humansService.index();
    allHeroes..addAll(allDroids)..addAll(allHumans);

    // Ignore the annoying cast here, hopefully Dart 2 fixes cases like this
    allHeroes = allHeroes
        .where((m) =>
            !args.containsKey('ep') ||
            (m['appears_in'].contains(args['ep']) as bool))
        .toList();

    return allHeroes.isEmpty ? null : allHeroes[rnd.nextInt(allHeroes.length)];
  };
}
