class Relationship {
  final String localKey;
  final String foreignKey;
  final String foreignTable;
  final bool cascadeOnDelete;

  const Relationship._(
      {this.localKey,
      this.foreignKey,
      this.foreignTable,
      this.cascadeOnDelete});
}

class HasMany extends Relationship {
  const HasMany(
      {String localKey,
      String foreignKey,
      String foreignTable,
      bool cascadeOnDelete: false})
      : super._(
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable,
            cascadeOnDelete: cascadeOnDelete == true);
}

const HasMany hasMany = const HasMany();

class HasOne extends Relationship {
  const HasOne(
      {String localKey,
      String foreignKey,
      String foreignTable,
      bool cascadeOnDelete: false})
      : super._(
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable,
            cascadeOnDelete: cascadeOnDelete == true);
}

const HasOne hasOne = const HasOne();

class BelongsTo extends Relationship {
  const BelongsTo({String localKey, String foreignKey, String foreignTable})
      : super._(
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable);
}

const BelongsTo belongsTo = const BelongsTo();
