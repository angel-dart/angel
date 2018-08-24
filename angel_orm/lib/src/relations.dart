abstract class RelationshipType {
  static const int hasMany = 0;
  static const int hasOne = 1;
  static const int belongsTo = 2;
  static const int belongsToMany = 3;
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
      : super(RelationshipType.hasMany,
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
      : super(RelationshipType.hasOne,
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable,
            cascadeOnDelete: cascadeOnDelete == true);
}

const HasOne hasOne = const HasOne();

class BelongsTo extends Relationship {
  const BelongsTo(
      {String localKey: 'id', String foreignKey, String foreignTable})
      : super(RelationshipType.belongsTo,
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable);
}

const BelongsTo belongsTo = const BelongsTo();

class BelongsToMany extends Relationship {
  const BelongsToMany(
      {String localKey: 'id', String foreignKey, String foreignTable})
      : super(RelationshipType.belongsToMany,
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable);
}

const BelongsToMany belongsToMany = const BelongsToMany();
