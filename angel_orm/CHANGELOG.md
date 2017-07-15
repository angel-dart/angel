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