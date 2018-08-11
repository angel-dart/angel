import 'package:angel_container/angel_container.dart';
import 'package:test/test.dart';

void testReflector(Reflector reflector) {
  var blaziken = new Pokemon('Blaziken', PokemonType.fire);
  Container container;

  setUp(() {
    container = new Container(reflector);
    container.singleton(blaziken);
  });

  test('make on singleton type returns singleton', () {
    expect(container.make(Pokemon), blaziken);
  });

  test('make on aliased singleton returns singleton', () {
    container.singleton(blaziken, as: StateError);
    expect(container.make(StateError), blaziken);
  });

  test('constructor injects singleton', () {
    var lower = container.make(LowerPokemon) as LowerPokemon;
    expect(lower.lowercaseName, blaziken.name.toLowerCase());
  });

  test('newInstance works', () {
    var type = container.reflector.reflectType(Pokemon);
    var instance =
        type.newInstance('changeName', [blaziken, 'Charizard']) as Pokemon;
    print(instance);
    expect(instance.name, 'Charizard');
    expect(instance.type, PokemonType.fire);
  });
}

class LowerPokemon {
  final Pokemon pokemon;

  LowerPokemon(this.pokemon);

  String get lowercaseName => pokemon.name.toLowerCase();
}

class Pokemon {
  final String name;
  final PokemonType type;

  Pokemon(this.name, this.type);

  factory Pokemon.changeName(Pokemon other, String name) {
    return new Pokemon(name, other.type);
  }

  @override
  String toString() => 'NAME: $name, TYPE: $type';
}

enum PokemonType { water, fire, grass, ice, poison, flying }
