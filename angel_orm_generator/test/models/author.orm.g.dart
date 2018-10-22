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
  Future<Author> getById(String id);
  Future<Author> createAuthor(Author model);
  Future<Author> updateAuthor(Author model);
  AuthorQuery query();
}

class AuthorQuery {}
