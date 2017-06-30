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
  const ColumnType._(this.name);

  static const ColumnType SMALL_SERIAL = const ColumnType._('smallserial');
  static const ColumnType SERIAL = const ColumnType._('serial');
  static const ColumnType BIG_SERIAL = const ColumnType._('bigserial');

  // Numbers
  static const ColumnType BIG_INT = const ColumnType._('bigint');
  static const ColumnType INT = const ColumnType._('int');
  static const ColumnType SMALL_INT = const ColumnType._('smallint');
  static const ColumnType TINY_INT = const ColumnType._('tinyint');
  static const ColumnType BIT = const ColumnType._('bit');
  static const ColumnType DECIMAL = const ColumnType._('decimal');
  static const ColumnType NUMERIC = const ColumnType._('numeric');
  static const ColumnType MONEY = const ColumnType._('money');
  static const ColumnType SMALL_MONEY = const ColumnType._('smallmoney');
  static const ColumnType FLOAT = const ColumnType._('float');
  static const ColumnType REAL = const ColumnType._('real');

  // Dates and times
  static const ColumnType DATE_TIME = const ColumnType._('datetime');
  static const ColumnType SMALL_DATE_TIME = const ColumnType._('smalldatetime');
  static const ColumnType DATE = const ColumnType._('date');
  static const ColumnType TIME = const ColumnType._('time');
  static const ColumnType TIME_STAMP = const ColumnType._('timestamp');

  // Strings
  static const ColumnType CHAR = const ColumnType._('char');
  static const ColumnType VAR_CHAR = const ColumnType._('varchar');
  static const ColumnType VAR_CHAR_MAX = const ColumnType._('varchar(max)');
  static const ColumnType TEXT = const ColumnType._('text');

  // Unicode strings
  static const ColumnType NCHAR = const ColumnType._('nchar');
  static const ColumnType NVAR_CHAR = const ColumnType._('nvarchar');
  static const ColumnType NVAR_CHAR_MAX = const ColumnType._('nvarchar(max)');
  static const ColumnType NTEXT = const ColumnType._('ntext');

  // Binary
  static const ColumnType BINARY = const ColumnType._('binary');
  static const ColumnType VAR_BINARY = const ColumnType._('varbinary');
  static const ColumnType VAR_BINARY_MAX = const ColumnType._('varbinary(max)');
  static const ColumnType IMAGE = const ColumnType._('image');

  // Misc.
  static const ColumnType SQL_VARIANT = const ColumnType._('sql_variant');
  static const ColumnType UNIQUE_IDENTIFIER =
      const ColumnType._('uniqueidentifier');
  static const ColumnType XML = const ColumnType._('xml');
  static const ColumnType CURSOR = const ColumnType._('cursor');
  static const ColumnType TABLE = const ColumnType._('table');
}
