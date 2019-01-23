import 'dart:convert';
import 'package:angel_migration/angel_migration.dart';
import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:collection/collection.dart';
part 'has_map.g.dart';

@orm
@serializable
abstract class _HasMap {
  Map get value;
}
