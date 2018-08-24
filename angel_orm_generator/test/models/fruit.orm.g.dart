// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// OrmGenerator
// **************************************************************************

import 'dart:async';
import 'fruit.dart';

abstract class FruitOrm {
  Future<List<Fruit>> getAll();
  Future<Fruit> getById(id);
  Future<Fruit> update(Fruit model);
  FruitQuery query();
}

class FruitQuery {}
