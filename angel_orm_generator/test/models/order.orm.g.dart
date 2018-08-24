// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// OrmGenerator
// **************************************************************************

import 'dart:async';
import 'order.dart';

abstract class OrderOrm {
  Future<List<Order>> getAll();
  Future<Order> getById(id);
  Future<Order> updateOrder(Order model);
  OrderQuery query();
}

class OrderQuery {}
