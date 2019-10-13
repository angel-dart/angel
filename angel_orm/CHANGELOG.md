# 2.1.0-beta.3
* Remove parentheses from `AS` when renaming raw `expressions`.

# 2.1.0-beta.2
* Add `expressions` to `Query`, to support custom SQL expressions that are
read as normal fields.

# 2.1.0-beta.1
* Calls to `leftJoin`, etc. alias all fields in a child query, to prevent
`ambiguous column a0.id` errors.

# 2.1.0-beta
* Split the formerly 600+ line `src/query.dart` up into
separate files.
* **BREAKING**: Add a required `QueryExecutor` argument to `transaction`
callbacks.
* Make `JoinBuilder` take `to` as a `String Function()`. This will allow
ORM queries to reference their joined subqueries.
* Removed deprecated `Join`, `toSql`, `sanitizeExpression`, `isAscii`.
* Always put `ORDER BY` before `LIMIT`.
* `and`, `or`, `not` in `QueryWhere` include parentheses.
* Add `joinType` to `Relationship` class.

# 2.0.2
* Place `LIMIT` and `OFFSET` after `ORDER BY`.

# 2.0.1
* Apply `package:pedantic` fixes.
* `@PrimaryKey()` no longer defaults to `serial`, allowing its type to be
inferenced.

# 2.0.0
* Add `isNull`, `isNotNull` getters to builders.

# 2.0.0-dev.24
* Fix a bug that caused syntax errors on `ORDER BY`.
* Add `pattern` to `like` on string builder. `sanitize` is optional.
* Add `RawSql`.

# 2.0.0-dev.23
* Add `@ManyToMany` annotation, which builds many-to-many relations.

# 2.0.0-dev.22
* `compileInsert` will explicitly never emit a key not belonging to the
associated query.

# 2.0.0-dev.21
* Add tableName to query

# 2.0.0-dev.20
* Join updates.

# 2.0.0-dev.19
* Implement cast-based `double` support.
* Finish `ListSqlExpressionBuilder`.

# 2.0.0-dev.18
* Add `ListSqlExpressionBuilder` (still in development).

# 2.0.0-dev.17
* Add `EnumSqlExpressionBuilder`.

# 2.0.0-dev.16
* Add `MapSqlExpressionBuilder` for JSON/JSONB support.

# 2.0.0-dev.15
* Remove `Column.defaultValue`.
* Deprecate `toSql` and `sanitizeExpression`.
* Refactor builders so that strings are passed through

# 2.0.0-dev.14
* Remove obsolete `@belongsToMany`.

# 2.0.0-dev.13
* Push for consistency with orm_gen @ `2.0.0-dev`.

# 2.0.0-dev.12
* Always apply `toSql` escapes.

# 2.0.0-dev.11
* Remove `limit(1)` except on `getOne`

# 2.0.0-dev.10
* Add `withFields` to `compile()`

# 2.0.0-dev.9
* Permanent preamble fix

# 2.0.0-dev.8
* Escapes

# 2.0.0-dev.7
* Update `toSql`
* Add `isTrue` and `isFalse`

# 2.0.0-dev.6
* Add `delete`, `insert` and `update` methods to `Query`.

# 2.0.0-dev.4
* Add more querying methods.
* Add preamble to `Query.compile`.

# 2.0.0-dev.3
* Brought back old-style query builder.
* Strong-mode updates, revised `Join`.

# 2.0.0-dev.2
* Renamed `ORM` to `Orm`.
* `Orm` now requires a database type.

# 2.0.0-dev.1
* Restored all old PostgreSQL-specific annotations. Rather than a smart runtime,
having a codegen capable of building ORM's for multiple databases can potentially
provide a very fast ORM for everyone.

# 2.0.0-dev
* Removed PostgreSQL-specific functionality, so that the ORM can ultimately
target all services.
* Created a better `Join` model.
* Created a far better `Query` model.
* Removed `lib/server.dart`

# 1.0.0-alpha+10
* Split into `angel_orm.dart` and `server.dart`. Prevents DDC failures.

# 1.0.0-alpha+7
* Added a `@belongsToMany` annotation class.
* Resolved [#20](https://github.com/angel-dart/orm/issues/20). The
`PostgreSQLConnectionPool` keeps track of which connections have been opened now.

# 1.0.0-alpha+6
* `DateTimeSqlExpressionBuilder` will no longer automatically
insert quotation marks around names.

# 1.0.0-alpha+5
* Corrected a typo that was causing the aforementioned test failures.
`==` becomes `=`.

# 1.0.0-alpha+4
* Added a null-check in `lib/src/query.dart#L24` to (hopefully) prevent it from
crashing on Travis.

# 1.0.0-alpha+3
* Added `isIn`, `isNotIn`, `isBetween`, `isNotBetween` to `SqlExpressionBuilder` and its
subclasses.
* Added a dependency on `package:meta`.
