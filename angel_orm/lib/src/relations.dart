abstract class RelationshipType {
  static const int hasMany = 0;
  static const int hasOne = 1;
  static const int belongsTo = 2;
  static const int manyToMany = 3;
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
      {String localKey = 'id',
      String foreignKey,
      String foreignTable,
      bool cascadeOnDelete = false})
      : super(RelationshipType.hasMany,
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable,
            cascadeOnDelete: cascadeOnDelete == true);
}

const HasMany hasMany = const HasMany();

class HasOne extends Relationship {
  const HasOne(
      {String localKey = 'id',
      String foreignKey,
      String foreignTable,
      bool cascadeOnDelete = false})
      : super(RelationshipType.hasOne,
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable,
            cascadeOnDelete: cascadeOnDelete == true);
}

const HasOne hasOne = const HasOne();

class BelongsTo extends Relationship {
  const BelongsTo({String localKey, String foreignKey, String foreignTable})
      : super(RelationshipType.belongsTo,
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable);
}

const BelongsTo belongsTo = const BelongsTo();

class ManyToMany extends Relationship {
  final Type through;

  const ManyToMany(this.through,
      {String localKey = 'id',
      String foreignKey,
      String foreignTable,
      bool cascadeOnDelete = false})
      : super(
            RelationshipType.hasMany, // Many-to-Many is actually just a hasMany
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable,
            cascadeOnDelete: cascadeOnDelete == true);
}
