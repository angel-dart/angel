import 'package:graphql_schema/graphql_schema.dart';
import 'package:test/test.dart';

void main() {
  var pokemonType = objectType('Pokémon', fields: [
    field('name', type: graphQLString.nonNullable()),
  ]);

  var isValidPokemon = predicate(
      (x) =>
          pokemonType.validate('@root', x as Map<String, dynamic>).successful,
      'is a valid Pokémon');

  var throwsATypeError =
      throwsA(predicate((x) => x is TypeError, 'is a type error'));

  test('mismatched scalar type', () {
    expect(() => pokemonType.validate('@root', {'name': 24}), throwsATypeError);
  });

  test('empty passed for non-nullable', () {
    expect(<String, dynamic>{}, isNot(isValidPokemon));
  });

  test('null passed for non-nullable', () {
    expect({'name': null}, isNot(isValidPokemon));
  });

  test('rejects extraneous fields', () {
    expect({'name': 'Vulpix', 'foo': 'bar'}, isNot(isValidPokemon));
  });
}
