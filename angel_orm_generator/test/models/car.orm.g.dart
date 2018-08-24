// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// OrmGenerator
// **************************************************************************

import 'dart:async';

import 'car.dart';

abstract class CarOrm {
  Future<List<Car>> getAll();

  Future<Car> getById(id);

  Future<Car> update(Car model);

  CarQuery query();
}

class CarQuery {}
