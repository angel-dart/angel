import 'package:graphql_schema/graphql_schema.dart';

final GraphQLObjectType pokemonType = objectType('Pokemon', fields:[
  field('species', type: graphQLString),
  field('catch_date', type: graphQLDate)
]);

final GraphQLObjectType trainerType =
    objectType('Trainer', fields:[field('name', type: graphQLString)]);

final GraphQLObjectType pokemonRegionType = objectType('PokemonRegion', fields:[
  field('trainer', type: trainerType),
  field('pokemon_species', type: listType(pokemonType))
]);
