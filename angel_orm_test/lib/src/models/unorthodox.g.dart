// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unorthodox.dart';

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class UnorthodoxMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('unorthodoxes', (table) {
      table.varChar('name');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('unorthodoxes');
  }
}

class WeirdJoinMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('weird_joins', (table) {
      table.integer('id')..primaryKey();
      table
          .declare('join_name', ColumnType('varchar'))
          .references('unorthodoxes', 'name');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('weird_joins', cascade: true);
  }
}

class SongMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('songs', (table) {
      table.serial('id')..primaryKey();
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
      table.integer('weird_join_id');
      table.varChar('title');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('songs');
  }
}

class NumbaMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('numbas', (table) {
      table.integer('i')..primaryKey();
      table.integer('parent');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('numbas');
  }
}

class FooMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('foos', (table) {
      table.varChar('bar')..primaryKey();
    });
  }

  @override
  down(Schema schema) {
    schema.drop('foos', cascade: true);
  }
}

class FooPivotMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('foo_pivots', (table) {
      table
          .declare('weird_join_id', ColumnType('int'))
          .references('weird_joins', 'id');
      table.declare('foo_bar', ColumnType('varchar')).references('foos', 'bar');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('foo_pivots');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class UnorthodoxQuery extends Query<Unorthodox, UnorthodoxQueryWhere> {
  UnorthodoxQuery({Query parent, Set<String> trampoline})
      : super(parent: parent) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = UnorthodoxQueryWhere(this);
  }

  @override
  final UnorthodoxQueryValues values = UnorthodoxQueryValues();

  UnorthodoxQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'unorthodoxes';
  }

  @override
  get fields {
    return const ['name'];
  }

  @override
  UnorthodoxQueryWhere get where {
    return _where;
  }

  @override
  UnorthodoxQueryWhere newWhereClause() {
    return UnorthodoxQueryWhere(this);
  }

  static Unorthodox parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Unorthodox(name: (row[0] as String));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class UnorthodoxQueryWhere extends QueryWhere {
  UnorthodoxQueryWhere(UnorthodoxQuery query)
      : name = StringSqlExpressionBuilder(query, 'name');

  final StringSqlExpressionBuilder name;

  @override
  get expressionBuilders {
    return [name];
  }
}

class UnorthodoxQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  String get name {
    return (values['name'] as String);
  }

  set name(String value) => values['name'] = value;
  void copyFrom(Unorthodox model) {
    name = model.name;
  }
}

class WeirdJoinQuery extends Query<WeirdJoin, WeirdJoinQueryWhere> {
  WeirdJoinQuery({Query parent, Set<String> trampoline})
      : super(parent: parent) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = WeirdJoinQueryWhere(this);
    leftJoin(
        _unorthodox = UnorthodoxQuery(trampoline: trampoline, parent: this),
        'join_name',
        'name',
        additionalFields: const ['name'],
        trampoline: trampoline);
    leftJoin(_song = SongQuery(trampoline: trampoline, parent: this), 'id',
        'weird_join_id',
        additionalFields: const [
          'id',
          'created_at',
          'updated_at',
          'weird_join_id',
          'title'
        ],
        trampoline: trampoline);
    leftJoin(_numbas = NumbaQuery(trampoline: trampoline, parent: this), 'id',
        'parent',
        additionalFields: const ['i', 'parent'], trampoline: trampoline);
    leftJoin(
        '(SELECT foo_pivots.weird_join_id, foos.bar FROM foos LEFT JOIN foo_pivots ON foo_pivots.foo_bar=foos.bar)',
        'id',
        'weird_join_id',
        additionalFields: const ['bar'],
        trampoline: trampoline);
  }

  @override
  final WeirdJoinQueryValues values = WeirdJoinQueryValues();

  WeirdJoinQueryWhere _where;

  UnorthodoxQuery _unorthodox;

  SongQuery _song;

  NumbaQuery _numbas;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'weird_joins';
  }

  @override
  get fields {
    return const ['id', 'join_name'];
  }

  @override
  WeirdJoinQueryWhere get where {
    return _where;
  }

  @override
  WeirdJoinQueryWhere newWhereClause() {
    return WeirdJoinQueryWhere(this);
  }

  static WeirdJoin parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = WeirdJoin(id: (row[0] as int));
    if (row.length > 2) {
      model = model.copyWith(
          unorthodox: UnorthodoxQuery.parseRow(row.skip(2).take(1).toList()));
    }
    if (row.length > 3) {
      model = model.copyWith(
          song: SongQuery.parseRow(row.skip(3).take(5).toList()));
    }
    if (row.length > 8) {
      model = model.copyWith(
          numbas: [NumbaQuery.parseRow(row.skip(8).take(2).toList())]
              .where((x) => x != null)
              .toList());
    }
    if (row.length > 10) {
      model = model.copyWith(
          foos: [FooQuery.parseRow(row.skip(10).take(1).toList())]
              .where((x) => x != null)
              .toList());
    }
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }

  UnorthodoxQuery get unorthodox {
    return _unorthodox;
  }

  SongQuery get song {
    return _song;
  }

  NumbaQuery get numbas {
    return _numbas;
  }

  @override
  bool canCompile(trampoline) {
    return (!(trampoline.contains('weird_joins') &&
        trampoline.contains('foo_pivots')));
  }

  @override
  get(QueryExecutor executor) {
    return super.get(executor).then((result) {
      return result.fold<List<WeirdJoin>>([], (out, model) {
        var idx = out.indexWhere((m) => m.id == model.id);

        if (idx == -1) {
          return out..add(model);
        } else {
          var l = out[idx];
          return out
            ..[idx] = l.copyWith(
                numbas: List<_Numba>.from(l.numbas ?? [])
                  ..addAll(model.numbas ?? []),
                foos: List<_Foo>.from(l.foos ?? [])..addAll(model.foos ?? []));
        }
      });
    });
  }

  @override
  update(QueryExecutor executor) {
    return super.update(executor).then((result) {
      return result.fold<List<WeirdJoin>>([], (out, model) {
        var idx = out.indexWhere((m) => m.id == model.id);

        if (idx == -1) {
          return out..add(model);
        } else {
          var l = out[idx];
          return out
            ..[idx] = l.copyWith(
                numbas: List<_Numba>.from(l.numbas ?? [])
                  ..addAll(model.numbas ?? []),
                foos: List<_Foo>.from(l.foos ?? [])..addAll(model.foos ?? []));
        }
      });
    });
  }

  @override
  delete(QueryExecutor executor) {
    return super.delete(executor).then((result) {
      return result.fold<List<WeirdJoin>>([], (out, model) {
        var idx = out.indexWhere((m) => m.id == model.id);

        if (idx == -1) {
          return out..add(model);
        } else {
          var l = out[idx];
          return out
            ..[idx] = l.copyWith(
                numbas: List<_Numba>.from(l.numbas ?? [])
                  ..addAll(model.numbas ?? []),
                foos: List<_Foo>.from(l.foos ?? [])..addAll(model.foos ?? []));
        }
      });
    });
  }
}

class WeirdJoinQueryWhere extends QueryWhere {
  WeirdJoinQueryWhere(WeirdJoinQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        joinName = StringSqlExpressionBuilder(query, 'join_name');

  final NumericSqlExpressionBuilder<int> id;

  final StringSqlExpressionBuilder joinName;

  @override
  get expressionBuilders {
    return [id, joinName];
  }
}

class WeirdJoinQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  int get id {
    return (values['id'] as int);
  }

  set id(int value) => values['id'] = value;
  String get joinName {
    return (values['join_name'] as String);
  }

  set joinName(String value) => values['join_name'] = value;
  void copyFrom(WeirdJoin model) {
    id = model.id;
    if (model.unorthodox != null) {
      values['join_name'] = model.unorthodox.name;
    }
  }
}

class SongQuery extends Query<Song, SongQueryWhere> {
  SongQuery({Query parent, Set<String> trampoline}) : super(parent: parent) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = SongQueryWhere(this);
  }

  @override
  final SongQueryValues values = SongQueryValues();

  SongQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'songs';
  }

  @override
  get fields {
    return const ['id', 'created_at', 'updated_at', 'weird_join_id', 'title'];
  }

  @override
  SongQueryWhere get where {
    return _where;
  }

  @override
  SongQueryWhere newWhereClause() {
    return SongQueryWhere(this);
  }

  static Song parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Song(
        id: row[0].toString(),
        createdAt: (row[1] as DateTime),
        updatedAt: (row[2] as DateTime),
        weirdJoinId: (row[3] as int),
        title: (row[4] as String));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class SongQueryWhere extends QueryWhere {
  SongQueryWhere(SongQuery query)
      : id = NumericSqlExpressionBuilder<int>(query, 'id'),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at'),
        weirdJoinId = NumericSqlExpressionBuilder<int>(query, 'weird_join_id'),
        title = StringSqlExpressionBuilder(query, 'title');

  final NumericSqlExpressionBuilder<int> id;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  final NumericSqlExpressionBuilder<int> weirdJoinId;

  final StringSqlExpressionBuilder title;

  @override
  get expressionBuilders {
    return [id, createdAt, updatedAt, weirdJoinId, title];
  }
}

class SongQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  String get id {
    return (values['id'] as String);
  }

  set id(String value) => values['id'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  int get weirdJoinId {
    return (values['weird_join_id'] as int);
  }

  set weirdJoinId(int value) => values['weird_join_id'] = value;
  String get title {
    return (values['title'] as String);
  }

  set title(String value) => values['title'] = value;
  void copyFrom(Song model) {
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
    weirdJoinId = model.weirdJoinId;
    title = model.title;
  }
}

class NumbaQuery extends Query<Numba, NumbaQueryWhere> {
  NumbaQuery({Query parent, Set<String> trampoline}) : super(parent: parent) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = NumbaQueryWhere(this);
  }

  @override
  final NumbaQueryValues values = NumbaQueryValues();

  NumbaQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'numbas';
  }

  @override
  get fields {
    return const ['i', 'parent'];
  }

  @override
  NumbaQueryWhere get where {
    return _where;
  }

  @override
  NumbaQueryWhere newWhereClause() {
    return NumbaQueryWhere(this);
  }

  static Numba parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Numba(i: (row[0] as int), parent: (row[1] as int));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class NumbaQueryWhere extends QueryWhere {
  NumbaQueryWhere(NumbaQuery query)
      : i = NumericSqlExpressionBuilder<int>(query, 'i'),
        parent = NumericSqlExpressionBuilder<int>(query, 'parent');

  final NumericSqlExpressionBuilder<int> i;

  final NumericSqlExpressionBuilder<int> parent;

  @override
  get expressionBuilders {
    return [i, parent];
  }
}

class NumbaQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  int get i {
    return (values['i'] as int);
  }

  set i(int value) => values['i'] = value;
  int get parent {
    return (values['parent'] as int);
  }

  set parent(int value) => values['parent'] = value;
  void copyFrom(Numba model) {
    i = model.i;
    parent = model.parent;
  }
}

class FooQuery extends Query<Foo, FooQueryWhere> {
  FooQuery({Query parent, Set<String> trampoline}) : super(parent: parent) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = FooQueryWhere(this);
    leftJoin(
        '(SELECT foo_pivots.foo_bar, weird_joins.id, weird_joins.join_name FROM weird_joins LEFT JOIN foo_pivots ON foo_pivots.weird_join_id=weird_joins.id)',
        'bar',
        'foo_bar',
        additionalFields: const ['id', 'join_name'],
        trampoline: trampoline);
  }

  @override
  final FooQueryValues values = FooQueryValues();

  FooQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'foos';
  }

  @override
  get fields {
    return const ['bar'];
  }

  @override
  FooQueryWhere get where {
    return _where;
  }

  @override
  FooQueryWhere newWhereClause() {
    return FooQueryWhere(this);
  }

  static Foo parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = Foo(bar: (row[0] as String));
    if (row.length > 1) {
      model = model.copyWith(
          weirdJoins: [WeirdJoinQuery.parseRow(row.skip(1).take(2).toList())]
              .where((x) => x != null)
              .toList());
    }
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }

  @override
  bool canCompile(trampoline) {
    return (!(trampoline.contains('foos') &&
        trampoline.contains('foo_pivots')));
  }

  @override
  get(QueryExecutor executor) {
    return super.get(executor).then((result) {
      return result.fold<List<Foo>>([], (out, model) {
        var idx = out.indexWhere((m) => m.bar == model.bar);

        if (idx == -1) {
          return out..add(model);
        } else {
          var l = out[idx];
          return out
            ..[idx] = l.copyWith(
                weirdJoins: List<_WeirdJoin>.from(l.weirdJoins ?? [])
                  ..addAll(model.weirdJoins ?? []));
        }
      });
    });
  }

  @override
  update(QueryExecutor executor) {
    return super.update(executor).then((result) {
      return result.fold<List<Foo>>([], (out, model) {
        var idx = out.indexWhere((m) => m.bar == model.bar);

        if (idx == -1) {
          return out..add(model);
        } else {
          var l = out[idx];
          return out
            ..[idx] = l.copyWith(
                weirdJoins: List<_WeirdJoin>.from(l.weirdJoins ?? [])
                  ..addAll(model.weirdJoins ?? []));
        }
      });
    });
  }

  @override
  delete(QueryExecutor executor) {
    return super.delete(executor).then((result) {
      return result.fold<List<Foo>>([], (out, model) {
        var idx = out.indexWhere((m) => m.bar == model.bar);

        if (idx == -1) {
          return out..add(model);
        } else {
          var l = out[idx];
          return out
            ..[idx] = l.copyWith(
                weirdJoins: List<_WeirdJoin>.from(l.weirdJoins ?? [])
                  ..addAll(model.weirdJoins ?? []));
        }
      });
    });
  }
}

class FooQueryWhere extends QueryWhere {
  FooQueryWhere(FooQuery query)
      : bar = StringSqlExpressionBuilder(query, 'bar');

  final StringSqlExpressionBuilder bar;

  @override
  get expressionBuilders {
    return [bar];
  }
}

class FooQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  String get bar {
    return (values['bar'] as String);
  }

  set bar(String value) => values['bar'] = value;
  void copyFrom(Foo model) {
    bar = model.bar;
  }
}

class FooPivotQuery extends Query<FooPivot, FooPivotQueryWhere> {
  FooPivotQuery({Query parent, Set<String> trampoline})
      : super(parent: parent) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = FooPivotQueryWhere(this);
    leftJoin(_weirdJoin = WeirdJoinQuery(trampoline: trampoline, parent: this),
        'weird_join_id', 'id',
        additionalFields: const ['id', 'join_name'], trampoline: trampoline);
    leftJoin(
        _foo = FooQuery(trampoline: trampoline, parent: this), 'foo_bar', 'bar',
        additionalFields: const ['bar'], trampoline: trampoline);
  }

  @override
  final FooPivotQueryValues values = FooPivotQueryValues();

  FooPivotQueryWhere _where;

  WeirdJoinQuery _weirdJoin;

  FooQuery _foo;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'foo_pivots';
  }

  @override
  get fields {
    return const ['weird_join_id', 'foo_bar'];
  }

  @override
  FooPivotQueryWhere get where {
    return _where;
  }

  @override
  FooPivotQueryWhere newWhereClause() {
    return FooPivotQueryWhere(this);
  }

  static FooPivot parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = FooPivot();
    if (row.length > 2) {
      model = model.copyWith(
          weirdJoin: WeirdJoinQuery.parseRow(row.skip(2).take(2).toList()));
    }
    if (row.length > 4) {
      model =
          model.copyWith(foo: FooQuery.parseRow(row.skip(4).take(1).toList()));
    }
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }

  WeirdJoinQuery get weirdJoin {
    return _weirdJoin;
  }

  FooQuery get foo {
    return _foo;
  }
}

class FooPivotQueryWhere extends QueryWhere {
  FooPivotQueryWhere(FooPivotQuery query)
      : weirdJoinId = NumericSqlExpressionBuilder<int>(query, 'weird_join_id'),
        fooBar = StringSqlExpressionBuilder(query, 'foo_bar');

  final NumericSqlExpressionBuilder<int> weirdJoinId;

  final StringSqlExpressionBuilder fooBar;

  @override
  get expressionBuilders {
    return [weirdJoinId, fooBar];
  }
}

class FooPivotQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  int get weirdJoinId {
    return (values['weird_join_id'] as int);
  }

  set weirdJoinId(int value) => values['weird_join_id'] = value;
  String get fooBar {
    return (values['foo_bar'] as String);
  }

  set fooBar(String value) => values['foo_bar'] = value;
  void copyFrom(FooPivot model) {
    if (model.weirdJoin != null) {
      values['weird_join_id'] = model.weirdJoin.id;
    }
    if (model.foo != null) {
      values['foo_bar'] = model.foo.bar;
    }
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Unorthodox implements _Unorthodox {
  const Unorthodox({this.name});

  @override
  final String name;

  Unorthodox copyWith({String name}) {
    return Unorthodox(name: name ?? this.name);
  }

  bool operator ==(other) {
    return other is _Unorthodox && other.name == name;
  }

  @override
  int get hashCode {
    return hashObjects([name]);
  }

  @override
  String toString() {
    return "Unorthodox(name=$name)";
  }

  Map<String, dynamic> toJson() {
    return UnorthodoxSerializer.toMap(this);
  }
}

@generatedSerializable
class WeirdJoin implements _WeirdJoin {
  const WeirdJoin(
      {this.id, this.unorthodox, this.song, this.numbas, this.foos});

  @override
  final int id;

  @override
  final _Unorthodox unorthodox;

  @override
  final _Song song;

  @override
  final List<_Numba> numbas;

  @override
  final List<_Foo> foos;

  WeirdJoin copyWith(
      {int id,
      _Unorthodox unorthodox,
      _Song song,
      List<_Numba> numbas,
      List<_Foo> foos}) {
    return WeirdJoin(
        id: id ?? this.id,
        unorthodox: unorthodox ?? this.unorthodox,
        song: song ?? this.song,
        numbas: numbas ?? this.numbas,
        foos: foos ?? this.foos);
  }

  bool operator ==(other) {
    return other is _WeirdJoin &&
        other.id == id &&
        other.unorthodox == unorthodox &&
        other.song == song &&
        ListEquality<_Numba>(DefaultEquality<_Numba>())
            .equals(other.numbas, numbas) &&
        ListEquality<_Foo>(DefaultEquality<_Foo>()).equals(other.foos, foos);
  }

  @override
  int get hashCode {
    return hashObjects([id, unorthodox, song, numbas, foos]);
  }

  @override
  String toString() {
    return "WeirdJoin(id=$id, unorthodox=$unorthodox, song=$song, numbas=$numbas, foos=$foos)";
  }

  Map<String, dynamic> toJson() {
    return WeirdJoinSerializer.toMap(this);
  }
}

@generatedSerializable
class Song extends _Song {
  Song({this.id, this.createdAt, this.updatedAt, this.weirdJoinId, this.title});

  /// A unique identifier corresponding to this item.
  @override
  String id;

  /// The time at which this item was created.
  @override
  DateTime createdAt;

  /// The last time at which this item was updated.
  @override
  DateTime updatedAt;

  @override
  final int weirdJoinId;

  @override
  final String title;

  Song copyWith(
      {String id,
      DateTime createdAt,
      DateTime updatedAt,
      int weirdJoinId,
      String title}) {
    return Song(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        weirdJoinId: weirdJoinId ?? this.weirdJoinId,
        title: title ?? this.title);
  }

  bool operator ==(other) {
    return other is _Song &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.weirdJoinId == weirdJoinId &&
        other.title == title;
  }

  @override
  int get hashCode {
    return hashObjects([id, createdAt, updatedAt, weirdJoinId, title]);
  }

  @override
  String toString() {
    return "Song(id=$id, createdAt=$createdAt, updatedAt=$updatedAt, weirdJoinId=$weirdJoinId, title=$title)";
  }

  Map<String, dynamic> toJson() {
    return SongSerializer.toMap(this);
  }
}

@generatedSerializable
class Numba extends _Numba {
  Numba({this.i, this.parent});

  @override
  int i;

  @override
  int parent;

  Numba copyWith({int i, int parent}) {
    return Numba(i: i ?? this.i, parent: parent ?? this.parent);
  }

  bool operator ==(other) {
    return other is _Numba && other.i == i && other.parent == parent;
  }

  @override
  int get hashCode {
    return hashObjects([i, parent]);
  }

  @override
  String toString() {
    return "Numba(i=$i, parent=$parent)";
  }

  Map<String, dynamic> toJson() {
    return NumbaSerializer.toMap(this);
  }
}

@generatedSerializable
class Foo implements _Foo {
  const Foo({this.bar, this.weirdJoins});

  @override
  final String bar;

  @override
  final List<_WeirdJoin> weirdJoins;

  Foo copyWith({String bar, List<_WeirdJoin> weirdJoins}) {
    return Foo(bar: bar ?? this.bar, weirdJoins: weirdJoins ?? this.weirdJoins);
  }

  bool operator ==(other) {
    return other is _Foo &&
        other.bar == bar &&
        ListEquality<_WeirdJoin>(DefaultEquality<_WeirdJoin>())
            .equals(other.weirdJoins, weirdJoins);
  }

  @override
  int get hashCode {
    return hashObjects([bar, weirdJoins]);
  }

  @override
  String toString() {
    return "Foo(bar=$bar, weirdJoins=$weirdJoins)";
  }

  Map<String, dynamic> toJson() {
    return FooSerializer.toMap(this);
  }
}

@generatedSerializable
class FooPivot implements _FooPivot {
  const FooPivot({this.weirdJoin, this.foo});

  @override
  final _WeirdJoin weirdJoin;

  @override
  final _Foo foo;

  FooPivot copyWith({_WeirdJoin weirdJoin, _Foo foo}) {
    return FooPivot(
        weirdJoin: weirdJoin ?? this.weirdJoin, foo: foo ?? this.foo);
  }

  bool operator ==(other) {
    return other is _FooPivot &&
        other.weirdJoin == weirdJoin &&
        other.foo == foo;
  }

  @override
  int get hashCode {
    return hashObjects([weirdJoin, foo]);
  }

  @override
  String toString() {
    return "FooPivot(weirdJoin=$weirdJoin, foo=$foo)";
  }

  Map<String, dynamic> toJson() {
    return FooPivotSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const UnorthodoxSerializer unorthodoxSerializer = UnorthodoxSerializer();

class UnorthodoxEncoder extends Converter<Unorthodox, Map> {
  const UnorthodoxEncoder();

  @override
  Map convert(Unorthodox model) => UnorthodoxSerializer.toMap(model);
}

class UnorthodoxDecoder extends Converter<Map, Unorthodox> {
  const UnorthodoxDecoder();

  @override
  Unorthodox convert(Map map) => UnorthodoxSerializer.fromMap(map);
}

class UnorthodoxSerializer extends Codec<Unorthodox, Map> {
  const UnorthodoxSerializer();

  @override
  get encoder => const UnorthodoxEncoder();
  @override
  get decoder => const UnorthodoxDecoder();
  static Unorthodox fromMap(Map map) {
    return Unorthodox(name: map['name'] as String);
  }

  static Map<String, dynamic> toMap(_Unorthodox model) {
    if (model == null) {
      return null;
    }
    return {'name': model.name};
  }
}

abstract class UnorthodoxFields {
  static const List<String> allFields = <String>[name];

  static const String name = 'name';
}

const WeirdJoinSerializer weirdJoinSerializer = WeirdJoinSerializer();

class WeirdJoinEncoder extends Converter<WeirdJoin, Map> {
  const WeirdJoinEncoder();

  @override
  Map convert(WeirdJoin model) => WeirdJoinSerializer.toMap(model);
}

class WeirdJoinDecoder extends Converter<Map, WeirdJoin> {
  const WeirdJoinDecoder();

  @override
  WeirdJoin convert(Map map) => WeirdJoinSerializer.fromMap(map);
}

class WeirdJoinSerializer extends Codec<WeirdJoin, Map> {
  const WeirdJoinSerializer();

  @override
  get encoder => const WeirdJoinEncoder();
  @override
  get decoder => const WeirdJoinDecoder();
  static WeirdJoin fromMap(Map map) {
    return WeirdJoin(
        id: map['id'] as int,
        unorthodox: map['unorthodox'] != null
            ? UnorthodoxSerializer.fromMap(map['unorthodox'] as Map)
            : null,
        song: map['song'] != null
            ? SongSerializer.fromMap(map['song'] as Map)
            : null,
        numbas: map['numbas'] is Iterable
            ? List.unmodifiable(((map['numbas'] as Iterable).whereType<Map>())
                .map(NumbaSerializer.fromMap))
            : null,
        foos: map['foos'] is Iterable
            ? List.unmodifiable(((map['foos'] as Iterable).whereType<Map>())
                .map(FooSerializer.fromMap))
            : null);
  }

  static Map<String, dynamic> toMap(_WeirdJoin model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'unorthodox': UnorthodoxSerializer.toMap(model.unorthodox),
      'song': SongSerializer.toMap(model.song),
      'numbas': model.numbas?.map((m) => NumbaSerializer.toMap(m))?.toList(),
      'foos': model.foos?.map((m) => FooSerializer.toMap(m))?.toList()
    };
  }
}

abstract class WeirdJoinFields {
  static const List<String> allFields = <String>[
    id,
    unorthodox,
    song,
    numbas,
    foos
  ];

  static const String id = 'id';

  static const String unorthodox = 'unorthodox';

  static const String song = 'song';

  static const String numbas = 'numbas';

  static const String foos = 'foos';
}

const SongSerializer songSerializer = SongSerializer();

class SongEncoder extends Converter<Song, Map> {
  const SongEncoder();

  @override
  Map convert(Song model) => SongSerializer.toMap(model);
}

class SongDecoder extends Converter<Map, Song> {
  const SongDecoder();

  @override
  Song convert(Map map) => SongSerializer.fromMap(map);
}

class SongSerializer extends Codec<Song, Map> {
  const SongSerializer();

  @override
  get encoder => const SongEncoder();
  @override
  get decoder => const SongDecoder();
  static Song fromMap(Map map) {
    return Song(
        id: map['id'] as String,
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at'].toString()))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at'].toString()))
            : null,
        weirdJoinId: map['weird_join_id'] as int,
        title: map['title'] as String);
  }

  static Map<String, dynamic> toMap(_Song model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String(),
      'weird_join_id': model.weirdJoinId,
      'title': model.title
    };
  }
}

abstract class SongFields {
  static const List<String> allFields = <String>[
    id,
    createdAt,
    updatedAt,
    weirdJoinId,
    title
  ];

  static const String id = 'id';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';

  static const String weirdJoinId = 'weird_join_id';

  static const String title = 'title';
}

const NumbaSerializer numbaSerializer = NumbaSerializer();

class NumbaEncoder extends Converter<Numba, Map> {
  const NumbaEncoder();

  @override
  Map convert(Numba model) => NumbaSerializer.toMap(model);
}

class NumbaDecoder extends Converter<Map, Numba> {
  const NumbaDecoder();

  @override
  Numba convert(Map map) => NumbaSerializer.fromMap(map);
}

class NumbaSerializer extends Codec<Numba, Map> {
  const NumbaSerializer();

  @override
  get encoder => const NumbaEncoder();
  @override
  get decoder => const NumbaDecoder();
  static Numba fromMap(Map map) {
    return Numba(i: map['i'] as int, parent: map['parent'] as int);
  }

  static Map<String, dynamic> toMap(_Numba model) {
    if (model == null) {
      return null;
    }
    return {'i': model.i, 'parent': model.parent};
  }
}

abstract class NumbaFields {
  static const List<String> allFields = <String>[i, parent];

  static const String i = 'i';

  static const String parent = 'parent';
}

const FooSerializer fooSerializer = FooSerializer();

class FooEncoder extends Converter<Foo, Map> {
  const FooEncoder();

  @override
  Map convert(Foo model) => FooSerializer.toMap(model);
}

class FooDecoder extends Converter<Map, Foo> {
  const FooDecoder();

  @override
  Foo convert(Map map) => FooSerializer.fromMap(map);
}

class FooSerializer extends Codec<Foo, Map> {
  const FooSerializer();

  @override
  get encoder => const FooEncoder();
  @override
  get decoder => const FooDecoder();
  static Foo fromMap(Map map) {
    return Foo(
        bar: map['bar'] as String,
        weirdJoins: map['weird_joins'] is Iterable
            ? List.unmodifiable(
                ((map['weird_joins'] as Iterable).whereType<Map>())
                    .map(WeirdJoinSerializer.fromMap))
            : null);
  }

  static Map<String, dynamic> toMap(_Foo model) {
    if (model == null) {
      return null;
    }
    return {
      'bar': model.bar,
      'weird_joins':
          model.weirdJoins?.map((m) => WeirdJoinSerializer.toMap(m))?.toList()
    };
  }
}

abstract class FooFields {
  static const List<String> allFields = <String>[bar, weirdJoins];

  static const String bar = 'bar';

  static const String weirdJoins = 'weird_joins';
}

const FooPivotSerializer fooPivotSerializer = FooPivotSerializer();

class FooPivotEncoder extends Converter<FooPivot, Map> {
  const FooPivotEncoder();

  @override
  Map convert(FooPivot model) => FooPivotSerializer.toMap(model);
}

class FooPivotDecoder extends Converter<Map, FooPivot> {
  const FooPivotDecoder();

  @override
  FooPivot convert(Map map) => FooPivotSerializer.fromMap(map);
}

class FooPivotSerializer extends Codec<FooPivot, Map> {
  const FooPivotSerializer();

  @override
  get encoder => const FooPivotEncoder();
  @override
  get decoder => const FooPivotDecoder();
  static FooPivot fromMap(Map map) {
    return FooPivot(
        weirdJoin: map['weird_join'] != null
            ? WeirdJoinSerializer.fromMap(map['weird_join'] as Map)
            : null,
        foo: map['foo'] != null
            ? FooSerializer.fromMap(map['foo'] as Map)
            : null);
  }

  static Map<String, dynamic> toMap(_FooPivot model) {
    if (model == null) {
      return null;
    }
    return {
      'weird_join': WeirdJoinSerializer.toMap(model.weirdJoin),
      'foo': FooSerializer.toMap(model.foo)
    };
  }
}

abstract class FooPivotFields {
  static const List<String> allFields = <String>[weirdJoin, foo];

  static const String weirdJoin = 'weird_join';

  static const String foo = 'foo';
}
