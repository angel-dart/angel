import 'package:angel_migration/angel_migration.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:angel_orm/angel_orm.dart';
part 'pokemon.g.dart';

enum PokemonType {
  fire,
  grass,
  water,
  dragon,
  poison,
  dark,
  fighting,
  electric,
  ghost
}

@serializable
@orm
abstract class _Pokemon extends Model {
  @notNull
  String get species;

  String get name;

  @notNull
  int get level;

  @notNull
  PokemonType get type1;

  PokemonType get type2;
}
