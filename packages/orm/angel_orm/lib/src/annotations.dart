/// A raw SQL statement that specifies a date/time default to the
/// current time.
const RawSql currentTimestamp = RawSql('CURRENT_TIMESTAMP');

/// Can passed to a [MigrationColumn] to default to a raw SQL expression.
class RawSql {
  /// The raw SQL text.
  final String value;

  const RawSql(this.value);
}

/// Canonical instance of [ORM]. Implies all defaults.
const Orm orm = Orm();

class Orm {
  /// The name of the table to query.
  ///
  /// Inferred if not present.
  final String tableName;

  /// Whether to generate migrations for this model.
  ///
  /// Defaults to [:true:].
  final bool generateMigrations;

  const Orm({this.tableName, this.generateMigrations = true});
}

/// The various types of join.
enum JoinType { inner, left, right, full, self }
