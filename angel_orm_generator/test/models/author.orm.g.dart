// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// OrmGenerator
// **************************************************************************

import 'dart:async';
import 'author.dart';

abstract class AuthorOrm {
  Future<List<Author>> getAll();
  Future<Author> getById(id);
  Future<Author> updateAuthor(Author model);
  AuthorQuery query();
}

class AuthorQuery {}
