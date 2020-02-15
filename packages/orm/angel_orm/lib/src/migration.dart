const List<String> SQL_RESERVED_WORDS = [
  'SELECT',
  'UPDATE',
  'INSERT',
  'DELETE',
  'FROM',
  'ASC',
  'DESC',
  'VALUES',
  'RETURNING',
  'ORDER',
  'BY',
];

/// Applies additional attributes to a database column.
class Column {
  /// If `true`, a SQL field will be nullable.
  final bool isNullable;

  /// Specifies the length of a `VARCHAR`.
  final int length;

  /// Explicitly defines a SQL type for this column.
  final ColumnType type;

  /// Specifies what kind of index this column is, if any.
  final IndexType indexType;

  /// A custom SQL expression to execute, instead of a named column.
  final String expression;

  const Column(
      {this.isNullable = true,
      this.length,
      this.type,
      this.indexType = IndexType.none,
      this.expression});

  /// Returns `true` if [expression] is not `null`.
  bool get hasExpression => expression != null;
}

class PrimaryKey extends Column {
  const PrimaryKey({ColumnType columnType})
      : super(type: columnType, indexType: IndexType.primaryKey);
}

const Column primaryKey = PrimaryKey();

/// Maps to SQL index types.
enum IndexType {
  none,

  /// Standard index.
  standardIndex,

  /// A primary key.
  primaryKey,

  /// A *unique* index.
  unique
}

/// Maps to SQL data types.
///
/// Features all types from this list: http://www.tutorialspoint.com/sql/sql-data-types.htm
class ColumnType {
  /// The name of this data type.
  final String name;

  const ColumnType(this.name);

  static const ColumnType boolean = ColumnType('boolean');

  static const ColumnType smallSerial = ColumnType('smallserial');
  static const ColumnType serial = ColumnType('serial');
  static const ColumnType bigSerial = ColumnType('bigserial');

  // Numbers
  static const ColumnType bigInt = ColumnType('bigint');
  static const ColumnType int = ColumnType('int');
  static const ColumnType smallInt = ColumnType('smallint');
  static const ColumnType tinyInt = ColumnType('tinyint');
  static const ColumnType bit = ColumnType('bit');
  static const ColumnType decimal = ColumnType('decimal');
  static const ColumnType numeric = ColumnType('numeric');
  static const ColumnType money = ColumnType('money');
  static const ColumnType smallMoney = ColumnType('smallmoney');
  static const ColumnType float = ColumnType('float');
  static const ColumnType real = ColumnType('real');

  // Dates and times
  static const ColumnType dateTime = ColumnType('datetime');
  static const ColumnType smallDateTime = ColumnType('smalldatetime');
  static const ColumnType date = ColumnType('date');
  static const ColumnType time = ColumnType('time');
  static const ColumnType timeStamp = ColumnType('timestamp');
  static const ColumnType timeStampWithTimeZone =
      ColumnType('timestamp with time zone');

  // Strings
  static const ColumnType char = ColumnType('char');
  static const ColumnType varChar = ColumnType('varchar');
  static const ColumnType varCharMax = ColumnType('varchar(max)');
  static const ColumnType text = ColumnType('text');

  // Unicode strings
  static const ColumnType nChar = ColumnType('nchar');
  static const ColumnType nVarChar = ColumnType('nvarchar');
  static const ColumnType nVarCharMax = ColumnType('nvarchar(max)');
  static const ColumnType nText = ColumnType('ntext');

  // Binary
  static const ColumnType binary = ColumnType('binary');
  static const ColumnType varBinary = ColumnType('varbinary');
  static const ColumnType varBinaryMax = ColumnType('varbinary(max)');
  static const ColumnType image = ColumnType('image');

  // JSON.
  static const ColumnType json = ColumnType('json');
  static const ColumnType jsonb = ColumnType('jsonb');

  // Misc.
  static const ColumnType sqlVariant = ColumnType('sql_variant');
  static const ColumnType uniqueIdentifier = ColumnType('uniqueidentifier');
  static const ColumnType xml = ColumnType('xml');
  static const ColumnType cursor = ColumnType('cursor');
  static const ColumnType table = ColumnType('table');
}
