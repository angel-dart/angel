// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// OrmGenerator
// **************************************************************************

import 'dart:async';
import 'foot.dart';

abstract class FootOrm {
  Future<List<Foot>> getAll();
  Future<Foot> getById(id);
  Future<Foot> updateFoot(Foot model);
  FootQuery query();
}

class FootQuery {}
