abstract class RelationshipType {
  static const int HAS_MANY = 0;
  static const int HAS_ONE = 1;
  static const int BELONGS_TO = 2;
}

class Relationship {
  final int type;
  final String localKey;
  final String foreignKey;
  final String foreignTable;
  final bool cascadeOnDelete;

  const Relationship(this.type,
      {this.localKey,
      this.foreignKey,
      this.foreignTable,
      this.cascadeOnDelete});
}

class HasMany extends Relationship {
  const HasMany(
      {String localKey: 'id',
      String foreignKey,
      String foreignTable,
      bool cascadeOnDelete: false})
      : super(0,
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable,
            cascadeOnDelete: cascadeOnDelete == true);
}

const HasMany hasMany = const HasMany();

class HasOne extends Relationship {
  const HasOne(
      {String localKey: 'id',
      String foreignKey,
      String foreignTable,
      bool cascadeOnDelete: false})
      : super(1,
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable,
            cascadeOnDelete: cascadeOnDelete == true);
}

const HasOne hasOne = const HasOne();

class BelongsTo extends Relationship {
  const BelongsTo(
      {String localKey: 'id', String foreignKey, String foreignTable})
      : super(2,
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable);
}

const BelongsTo belongsTo = const BelongsTo();
