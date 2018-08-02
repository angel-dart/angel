import 'package:graphql_schema/graphql_schema.dart';
import 'package:test/test.dart';
import 'common.dart';

main() {
  test('scalar', () {
    expect(graphQLString.serialize('a'), 'a');

    var now = new DateTime.now();
    expect(graphQLDate.serialize(now), now.toIso8601String());
  });

  test('list', () {
    expect(listType(graphQLString).serialize(['foo', 'bar']), ['foo', 'bar']);

    var today = new DateTime.now();
    var tomorrow = today.add(new Duration(days: 1));
    expect(listType(graphQLDate).serialize([today, tomorrow]),
        [today.toIso8601String(), tomorrow.toIso8601String()]);
  });

  test('object', () {
    var catchDate = new DateTime.now();

    var pikachu = {'species': 'Pikachu', 'catch_date': catchDate};

    expect(pokemonType.serialize(pikachu),
        {'species': 'Pikachu', 'catch_date': catchDate.toIso8601String()});
  });

  test('nested object', () {
    var pikachuDate = new DateTime.now(),
        charizardDate = pikachuDate.subtract(new Duration(days: 10));

    var pikachu = {'species': 'Pikachu', 'catch_date': pikachuDate};
    var charizard = {'species': 'Charizard', 'catch_date': charizardDate};

    var trainer = {'name': 'Tobe O'};

    var region = pokemonRegionType.serialize({
      'trainer': trainer,
      'pokemon_species': [pikachu, charizard]
    });
    print(region);

    expect(region, {
      'trainer': trainer,
      'pokemon_species': [
        {'species': 'Pikachu', 'catch_date': pikachuDate.toIso8601String()},
        {'species': 'Charizard', 'catch_date': charizardDate.toIso8601String()}
      ]
    });

    expect(() => pokemonRegionType.serialize({
      'trainer': trainer,
      'DIGIMON_species': [pikachu, charizard]
    }), throwsUnsupportedError);
  });
}
