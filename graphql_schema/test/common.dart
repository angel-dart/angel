import 'package:graphql_schema/graphql_schema.dart';

final GraphQLObjectType pokemonType = objectType('Pokemon', [
  field('species', type: graphQLString),
  field('catch_date', type: graphQLDate)
]);

final GraphQLObjectType trainerType =
    objectType('Trainer', [field('name', type: graphQLString)]);

final GraphQLObjectType pokemonRegionType = objectType('PokemonRegion', [
  field('trainer', type: trainerType),
  field('pokemon_species', type: listType(pokemonType))
]);
