// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// OrmGenerator
// **************************************************************************

import 'dart:async';
import 'customer.dart';

abstract class CustomerOrm {
  Future<List<Customer>> getAll();
  Future<Customer> getById(id);
  Future<Customer> updateCustomer(Customer model);
  CustomerQuery query();
}

class CustomerQuery {}
