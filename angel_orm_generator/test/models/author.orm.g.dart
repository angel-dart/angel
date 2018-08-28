// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// OrmGenerator
// **************************************************************************

import 'author.dart';
import 'dart:async';
import 'package:postgres/postgres.dart';
part 'author.postgresql.orm.g.dart';

abstract class AuthorOrm {
  factory AuthorOrm.postgreSql(PostgreSQLConnection connection) =
      _PostgreSqlAuthorOrmImpl;

  Future<List<Author>> getAll();
  Future<Author> getById(id);
  Future<Author> update(Author model);
  AuthorQuery query();
}

class AuthorQuery {}
