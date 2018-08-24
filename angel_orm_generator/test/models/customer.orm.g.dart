// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// OrmGenerator
// **************************************************************************

import 'dart:async';
import 'customer.dart';
part 'customer.postgresql.orm.dart';

abstract class CustomerOrm {
  Future<List<Customer>> getAll();
  Future<Customer> getById(id);
  Future<Customer> update(Customer model);
  CustomerQuery query();
}

class CustomerQuery {}
