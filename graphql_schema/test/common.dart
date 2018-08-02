import 'package:graphql_schema/graphql_schema.dart';

final GraphQLObjectType pokemonType = objectType('Pokemon', [
  field('species', innerType: graphQLString),
  field('catch_date', innerType: graphQLDate)
]);

final GraphQLObjectType trainerType =
    objectType('Trainer', [field('name', innerType: graphQLString)]);

final GraphQLObjectType pokemonRegionType = objectType('PokemonRegion', [
  field('trainer', innerType: trainerType),
  field('pokemon_species', innerType: listType(pokemonType))
]);
