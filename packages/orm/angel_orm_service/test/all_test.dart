import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_orm_postgres/angel_orm_postgres.dart';
import 'package:angel_orm_service/angel_orm_service.dart';
import 'package:logging/logging.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'pokemon.dart';

void main() {
  Logger logger;
  PostgreSqlExecutor executor;
  Service<int, Pokemon> pokemonService;

  setUp(() async {
    var conn = PostgreSQLConnection('localhost', 5432, 'angel_orm_service_test',
        username: Platform.environment['POSTGRES_USERNAME'] ?? 'postgres',
        password: Platform.environment['POSTGRES_PASSWORD'] ?? 'password');
    hierarchicalLoggingEnabled = true;
    logger = Logger.detached('orm_service');
    logger.level = Level.ALL;
    if (Platform.environment['log'] == '1') logger.onRecord.listen(print);
    executor = PostgreSqlExecutor(conn, logger: logger);
    await conn.open();
    await conn.query('''
    CREATE TEMPORARY TABLE pokemons (
      id serial,
      species varchar,
      name varchar,
      level integer,
      type1 integer,
      type2 integer,
      created_at timestamp,
      updated_at timestamp
    );
    ''');

    pokemonService = OrmService(executor, () => PokemonQuery());
  });

  tearDown(() async {
    await executor.close();
    pokemonService.close();
    logger.clearListeners();
  });

  test('create', () async {
    var blaziken = await pokemonService.create(Pokemon(
        species: 'Blaziken',
        level: 100,
        type1: PokemonType.fire,
        type2: PokemonType.fighting));
    print(blaziken);
    expect(blaziken.id, isNotNull);
    expect(blaziken.species, 'Blaziken');
    expect(blaziken.level, 100);
    expect(blaziken.type1, PokemonType.fire);
    expect(blaziken.type2, PokemonType.fighting);
  });

  group('after create', () {
    Pokemon giratina, pikachu;

    setUp(() async {
      giratina = await pokemonService.create(Pokemon(
          species: 'Giratina',
          name: 'My First Legendary',
          level: 54,
          type1: PokemonType.ghost,
          type2: PokemonType.dragon));
      pikachu = await pokemonService.create(Pokemon(
        species: 'Pikachu',
        level: 100,
        type1: PokemonType.electric,
      ));
    });

    group('index', () {
      test('default', () async {
        expect(await pokemonService.index(), contains(giratina));
        expect(await pokemonService.index(), contains(pikachu));
      });

      test('with callback', () async {
        var result = await pokemonService.index({
          'query': (PokemonQuery query) async {
            query.where.level.equals(pikachu.level);
          },
        });

        expect(result, [pikachu]);
      });

      test('search params', () async {
        Future<List<Pokemon>> searchByType1(PokemonType type1) async {
          var query = {PokemonFields.type1: type1};
          var params = {'query': query};
          return await pokemonService.index(params);
        }

        expect(await searchByType1(PokemonType.ghost), [giratina]);
        expect(await searchByType1(PokemonType.electric), [pikachu]);
        expect(await searchByType1(PokemonType.grass), []);
      });

      group(r'$sort', () {
        test('by name', () async {
          expect(
              await pokemonService.index({
                'query': {r'$sort': 'level'}
              }),
              [giratina, pikachu]);
        });

        test('map number', () async {
          expect(
              await pokemonService.index({
                'query': {
                  r'$sort': {'type1': -1}
                }
              }),
              [giratina, pikachu]);
          expect(
              await pokemonService.index({
                'query': {
                  r'$sort': {'type1': 100}
                }
              }),
              [pikachu, giratina]);
        });

        test('map string', () async {
          expect(
              await pokemonService.index({
                'query': {
                  r'$sort': {'type1': '-1'}
                }
              }),
              [giratina, pikachu]);
          expect(
              await pokemonService.index({
                'query': {
                  r'$sort': {'type1': 'foo'}
                }
              }),
              [pikachu, giratina]);
        });
      });
    });

    group('findOne', () {
      test('default', () async {
        expect(
            await pokemonService.findOne({
              'query': {PokemonFields.name: giratina.name}
            }),
            giratina);
        expect(
            await pokemonService.findOne({
              'query': {PokemonFields.level: pikachu.level}
            }),
            pikachu);
        expect(
            () => pokemonService.findOne({
                  'query': {PokemonFields.level: pikachu.level * 3}
                }),
            throwsA(TypeMatcher<AngelHttpException>()));
      });

      test('nonexistent throws 404', () {
        expect(
            () => pokemonService.findOne({
                  'query': {PokemonFields.type1: PokemonType.poison}
                }),
            throwsA(TypeMatcher<AngelHttpException>()));
      });
    });

    group('read', () {
      test('default', () async {
        expect(await pokemonService.read(pikachu.idAsInt), pikachu);
        expect(await pokemonService.read(giratina.idAsInt), giratina);
      });

      test('nonexistent throws 404', () {
        expect(() => pokemonService.read(999),
            throwsA(TypeMatcher<AngelHttpException>()));
      });
    });

    test('readMany', () async {
      expect(pokemonService.readMany([giratina.idAsInt, pikachu.idAsInt]),
          completion([giratina, pikachu]));
      expect(
          pokemonService.readMany([giratina.idAsInt]), completion([giratina]));
      expect(pokemonService.readMany([pikachu.idAsInt]), completion([pikachu]));
      expect(() => pokemonService.readMany([]), throwsArgumentError);
    });

    group('update', () {
      test('default', () async {
        expect(
            await pokemonService.update(
                giratina.idAsInt, giratina.copyWith(name: 'Hello')),
            giratina.copyWith(name: 'Hello'));
      });

      test('nonexistent throws 404', () {
        expect(
            () => pokemonService.update(999, giratina.copyWith(name: 'Hello')),
            throwsA(TypeMatcher<AngelHttpException>()));
      });
    });

    group('remove', () {
      test('default', () async {
        expect(pokemonService.read(giratina.idAsInt), completion(giratina));
        expect(pokemonService.read(pikachu.idAsInt), completion(pikachu));
      });

      test('nonexistent throws 404', () {
        expect(() => pokemonService.remove(999),
            throwsA(TypeMatcher<AngelHttpException>()));
      });

      test('cannot remove all unless explicitly set', () async {
        expect(() => pokemonService.remove(null, {'provider': Providers.rest}),
            throwsA(TypeMatcher<AngelHttpException>()));
      });
    });
  });
}
