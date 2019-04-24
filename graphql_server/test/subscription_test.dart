import 'dart:async';
import 'package:graphql_schema/graphql_schema.dart';
import 'package:graphql_server/graphql_server.dart';
import 'package:test/test.dart';

void main() {
  var episodes = [
    {'name': 'The Phantom Menace'},
    {'name': 'Attack of the Clones'},
    {'name': 'Attack of the Clones'}
  ];
  var episodesAsData = episodes.map((ep) {
    return {
      'data': {'prequels': ep}
    };
  });

  Stream<Map<String, dynamic>> resolveEpisodes(_, __) =>
      Stream.fromIterable(episodes)
          .map((ep) => {'prequels': ep, 'not_selected': 1337});

  var episodeType = objectType('Episode', fields: [
    field('name', graphQLString.nonNullable()),
    field('not_selected', graphQLInt),
  ]);

  var schema = graphQLSchema(
    queryType: objectType('TestQuery', fields: [
      field('episodes', graphQLInt, resolve: (_, __) => episodes),
    ]),
    subscriptionType: objectType('TestSubscription', fields: [
      field('prequels', episodeType, resolve: resolveEpisodes),
    ]),
  );

  var graphQL = GraphQL(schema);

  test('subscribe with selection', () async {
    var stream = await graphQL.parseAndExecute('''
    subscription {
      prequels {
        name
      }
    }
    ''') as Stream<Map<String, dynamic>>;

    var asList = await stream.toList();
    print(asList);
    expect(asList, episodesAsData);
  });
}
