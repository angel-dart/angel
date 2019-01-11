const List<String> SQL_RESERVED_WORDS = const [
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

  const Column(
      {this.isNullable: true,
      this.length,
      this.type,
      this.indexType: IndexType.none});
}

class PrimaryKey extends Column {
  const PrimaryKey({ColumnType columnType})
      : super(
            type: columnType ?? ColumnType.serial,
            indexType: IndexType.primaryKey);
}

const Column primaryKey = const PrimaryKey();

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

  static const ColumnType boolean = const ColumnType('boolean');

  static const ColumnType smallSerial = const ColumnType('smallserial');
  static const ColumnType serial = const ColumnType('serial');
  static const ColumnType bigSerial = const ColumnType('bigserial');

  // Numbers
  static const ColumnType bigInt = const ColumnType('bigint');
  static const ColumnType int = const ColumnType('int');
  static const ColumnType smallInt = const ColumnType('smallint');
  static const ColumnType tinyInt = const ColumnType('tinyint');
  static const ColumnType bit = const ColumnType('bit');
  static const ColumnType decimal = const ColumnType('decimal');
  static const ColumnType numeric = const ColumnType('numeric');
  static const ColumnType money = const ColumnType('money');
  static const ColumnType smallMoney = const ColumnType('smallmoney');
  static const ColumnType float = const ColumnType('float');
  static const ColumnType real = const ColumnType('real');

  // Dates and times
  static const ColumnType dateTime = const ColumnType('datetime');
  static const ColumnType smallDateTime = const ColumnType('smalldatetime');
  static const ColumnType date = const ColumnType('date');
  static const ColumnType time = const ColumnType('time');
  static const ColumnType timeStamp = const ColumnType('timestamp');
  static const ColumnType timeStampWithTimeZone =
      const ColumnType('timestamp with time zone');

  // Strings
  static const ColumnType char = const ColumnType('char');
  static const ColumnType varChar = const ColumnType('varchar');
  static const ColumnType varCharMax = const ColumnType('varchar(max)');
  static const ColumnType text = const ColumnType('text');

  // Unicode strings
  static const ColumnType nChar = const ColumnType('nchar');
  static const ColumnType nVarChar = const ColumnType('nvarchar');
  static const ColumnType nVarCharMax = const ColumnType('nvarchar(max)');
  static const ColumnType nText = const ColumnType('ntext');

  // Binary
  static const ColumnType binary = const ColumnType('binary');
  static const ColumnType varBinary = const ColumnType('varbinary');
  static const ColumnType varBinaryMax = const ColumnType('varbinary(max)');
  static const ColumnType image = const ColumnType('image');

  // JSON.
  static const ColumnType json = const ColumnType('json');
  static const ColumnType jsonb = const ColumnType('jsonb');

  // Misc.
  static const ColumnType sqlVariant = const ColumnType('sql_variant');
  static const ColumnType uniqueIdentifier =
      const ColumnType('uniqueidentifier');
  static const ColumnType xml = const ColumnType('xml');
  static const ColumnType cursor = const ColumnType('cursor');
  static const ColumnType table = const ColumnType('table');
}
