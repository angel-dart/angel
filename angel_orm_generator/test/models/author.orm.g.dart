// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// OrmGenerator
// **************************************************************************

import 'dart:async';
import 'author.dart';
part 'author.postgresql.orm.g.dart';

abstract class AuthorOrm {
  Future<List<Author>> getAll();
  Future<Author> getById(id);
  Future<Author> update(Author model);
  AuthorQuery query();
}

class AuthorQuery {}
