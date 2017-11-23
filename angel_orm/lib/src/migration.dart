const List<String> SQL_RESERVED_WORDS = const [
  'SELECT', 'UPDATE', 'INSERT', 'DELETE', 'FROM', 'ASC', 'DESC', 'VALUES', 'RETURNING', 'ORDER', 'BY',
];

/// Applies additional attributes to a database column.
class Column {
  /// If `true`, a SQL field will be nullable.
  final bool nullable;

  /// Specifies the length of a `VARCHAR`.
  final int length;

  /// Explicitly defines a SQL type for this column.
  final ColumnType type;

  /// Specifies what kind of index this column is, if any.
  final IndexType index;

  /// The default value of this field.
  final defaultValue;

  const Column(
      {this.nullable: true,
      this.length,
      this.type,
      this.index: IndexType.NONE,
      this.defaultValue});
}

class PrimaryKey extends Column {
  const PrimaryKey({ColumnType columnType})
      : super(
            type: columnType ?? ColumnType.SERIAL,
            index: IndexType.PRIMARY_KEY);
}

const Column primaryKey = const PrimaryKey();

/// Maps to SQL index types.
enum IndexType {
  NONE,

  /// Standard index.
  INDEX,

  /// A primary key.
  PRIMARY_KEY,

  /// A *unique* index.
  UNIQUE
}

/// Maps to SQL data types.
///
/// Features all types from this list: http://www.tutorialspoint.com/sql/sql-data-types.htm
class ColumnType {
  /// The name of this data type.
  final String name;
  const ColumnType(this.name);

  static const ColumnType BOOLEAN = const ColumnType('boolean');

  static const ColumnType SMALL_SERIAL = const ColumnType('smallserial');
  static const ColumnType SERIAL = const ColumnType('serial');
  static const ColumnType BIG_SERIAL = const ColumnType('bigserial');

  // Numbers
  static const ColumnType BIG_INT = const ColumnType('bigint');
  static const ColumnType INT = const ColumnType('int');
  static const ColumnType SMALL_INT = const ColumnType('smallint');
  static const ColumnType TINY_INT = const ColumnType('tinyint');
  static const ColumnType BIT = const ColumnType('bit');
  static const ColumnType DECIMAL = const ColumnType('decimal');
  static const ColumnType NUMERIC = const ColumnType('numeric');
  static const ColumnType MONEY = const ColumnType('money');
  static const ColumnType SMALL_MONEY = const ColumnType('smallmoney');
  static const ColumnType FLOAT = const ColumnType('float');
  static const ColumnType REAL = const ColumnType('real');

  // Dates and times
  static const ColumnType DATE_TIME = const ColumnType('datetime');
  static const ColumnType SMALL_DATE_TIME = const ColumnType('smalldatetime');
  static const ColumnType DATE = const ColumnType('date');
  static const ColumnType TIME = const ColumnType('time');
  static const ColumnType TIME_STAMP = const ColumnType('timestamp');
  static const ColumnType TIME_STAMP_WITH_TIME_ZONE = const ColumnType('timestamp with time zone');

  // Strings
  static const ColumnType CHAR = const ColumnType('char');
  static const ColumnType VAR_CHAR = const ColumnType('varchar');
  static const ColumnType VAR_CHAR_MAX = const ColumnType('varchar(max)');
  static const ColumnType TEXT = const ColumnType('text');

  // Unicode strings
  static const ColumnType NCHAR = const ColumnType('nchar');
  static const ColumnType NVAR_CHAR = const ColumnType('nvarchar');
  static const ColumnType NVAR_CHAR_MAX = const ColumnType('nvarchar(max)');
  static const ColumnType NTEXT = const ColumnType('ntext');

  // Binary
  static const ColumnType BINARY = const ColumnType('binary');
  static const ColumnType VAR_BINARY = const ColumnType('varbinary');
  static const ColumnType VAR_BINARY_MAX = const ColumnType('varbinary(max)');
  static const ColumnType IMAGE = const ColumnType('image');

  // Misc.
  static const ColumnType SQL_VARIANT = const ColumnType('sql_variant');
  static const ColumnType UNIQUE_IDENTIFIER =
      const ColumnType('uniqueidentifier');
  static const ColumnType XML = const ColumnType('xml');
  static const ColumnType CURSOR = const ColumnType('cursor');
  static const ColumnType TABLE = const ColumnType('table');
}
