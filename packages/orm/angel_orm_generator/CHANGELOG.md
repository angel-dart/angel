# 2.1.0-beta.2
* Support for custom SQL expressions.

# 2.1.0-beta.1
* `OrmBuildContext` caching is now local to a `Builder`, so `watch`
*should* finally always run when required. Should resolve
[#85](https://github.com/angel-dart/orm/issues/85).

# 2.1.0-beta
* Relationships have always generated subqueries; now these subqueries are
available as `Query` objects on generated classes.
* Support explicitly-defined join types for relations.

# 2.0.5
* Remove `ShimFieldImpl` check, which broke relations.
* Fix bug where primary key type would not be emitted in migrations.
* Fix `ManyToMany` ignoring primary key types.

# 2.0.4
* Fix `reviveColumn` and element finding to properly detect all annotations now.

# 2.0.3
* Remove `targets` in `build.yaml`.

# 2.0.2
* Change `build_config` range to `">=0.3.0 <0.5.0"`.

# 2.0.1
* Gracefully handle `null` in enum fields.
* Add `take` to wherever `skip` is used.

# 2.0.0+2
* Widen `analyzer` dependency range.

# 2.0.0+1
* Restore `build.yaml`, which at some point, got deleted.

# 2.0.0
* `parse` -> `tryParse` where used.

# 2.0.0-dev.7
* Handle `@ManyToMany`.
* Handle cases where the class is not a `Model`.
    * Stop assuming things have `id`, etc.
* Resolve a bug where the `indexType` of `@Column` annotations. would not be found.
* Add `cascade: true` to drops for hasOne/hasMany/ManyToMany migrations.
* Support enum default values in migrations.

# 2.0.0-dev.6
* Fix bug where an extra field would be inserted into joins and botch the result.
* Narrow analyzer dependency.

# 2.0.0-dev.5
* Implement cast-based `double` support.
* Finish `ListSqlExpressionBuilder`.

# 2.0.0-dev.4
* List generation support.

# 2.0.0-dev.3
* Add JSON/JSONB support for Maps.

# 2.0.0-dev.2
* Changes to work with `package:angel_orm@2.0.0-dev.15`.

# 2.0.0-dev.1
* Generate migration files.

# 2.0.0-dev
* Dart 2 updates, and more.

# 1.0.0-alpha+6
* `DateTime` is now `CAST` on insertion and update operations.

# 1.0.0-alpha+3
Implemented `@hasOne`, with tests. Still missing `@hasMany`.
`belongsToMany` will likely be scrapped.

# 1.0.0-alpha+2
* Added support for `belongsTo` relationships. Still missing `hasOne`, `hasMany`, `belongsToMany`.

# 1.0.0-alpha+1
* Closed #12. `insertX` and `updateX` now use `rc.camelCase`, instead of `rc.snakeCase`.
* Closed #13. Added `limit` and `offset` properties to `XQuery`.
* Closed #14. Refined the `or` method (it now takes an `XQueryWhere`), and removed `and` and `not`.
* Closed #16. Added `sortAscending` and `sortDescending` to `XQuery`.
* Closed #17. `delete` now uses `toSql` from `XQuery`.
* Closed #18. `XQuery` now supports `union` and `unionAll`.
