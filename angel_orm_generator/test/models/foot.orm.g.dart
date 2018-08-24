// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// OrmGenerator
// **************************************************************************

import 'dart:async';
import 'foot.dart';
part 'foot.postgresql.orm.dart';

abstract class FootOrm {
  Future<List<Foot>> getAll();
  Future<Foot> getById(id);
  Future<Foot> update(Foot model);
  FootQuery query();
}

class FootQuery {}
