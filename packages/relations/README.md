# relations
[![version 1.0.1](https://img.shields.io/badge/pub-v1.0.1-brightgreen.svg)](https://pub.dartlang.org/packages/angel_relations)
[![build status](https://travis-ci.org/angel-dart/relations.svg)](https://travis-ci.org/angel-dart/relations)

Database-agnostic relations between Angel services.

```dart
// Authors owning one book
app.service('authors').afterAll(
    relations.hasOne('books', as: 'book', foreignKey: 'authorId'));

// Or multiple
app.service('authors').afterAll(
    relations.hasMany('books', foreignKey: 'authorId'));

// Or, books belonging to authors
app.service('books').afterAll(relations.belongsTo('authors'));
```

Supports:
* `hasOne`
* `hasMany`
* `hasManyThrough`
* `belongsTo`
* `belongsToMany`