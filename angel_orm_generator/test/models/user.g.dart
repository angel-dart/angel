// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.user;

// **************************************************************************
// MigrationGenerator
// **************************************************************************

class UserMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('users', (table) {
      table.serial('id')..primaryKey();
      table.varChar('username');
      table.varChar('password');
      table.varChar('email');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('users');
  }
}

class RoleUserMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('role_users', (table) {
      table.serial('id')..primaryKey();
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
      table.integer('role_id').references('roles', 'id');
      table.integer('user_id').references('users', 'id');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('role_users');
  }
}

class RoleMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('roles', (table) {
      table.serial('id')..primaryKey();
      table.varChar('name');
      table.timeStamp('created_at');
      table.timeStamp('updated_at');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('roles');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class UserQuery extends Query<User, UserQueryWhere> {
  UserQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = new UserQueryWhere(this);
  }

  @override
  final UserQueryValues values = new UserQueryValues();

  UserQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'users';
  }

  @override
  get fields {
    return const [
      'id',
      'username',
      'password',
      'email',
      'created_at',
      'updated_at'
    ];
  }

  @override
  UserQueryWhere get where {
    return _where;
  }

  @override
  UserQueryWhere newWhereClause() {
    return new UserQueryWhere(this);
  }

  static User parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = new User(
        id: row[0].toString(),
        username: (row[1] as String),
        password: (row[2] as String),
        email: (row[3] as String),
        createdAt: (row[4] as DateTime),
        updatedAt: (row[5] as DateTime));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class UserQueryWhere extends QueryWhere {
  UserQueryWhere(UserQuery query)
      : id = new NumericSqlExpressionBuilder<int>(query, 'id'),
        username = new StringSqlExpressionBuilder(query, 'username'),
        password = new StringSqlExpressionBuilder(query, 'password'),
        email = new StringSqlExpressionBuilder(query, 'email'),
        createdAt = new DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = new DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final StringSqlExpressionBuilder username;

  final StringSqlExpressionBuilder password;

  final StringSqlExpressionBuilder email;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  @override
  get expressionBuilders {
    return [id, username, password, email, createdAt, updatedAt];
  }
}

class UserQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  int get id {
    return (values['id'] as int);
  }

  set id(int value) => values['id'] = value;
  String get username {
    return (values['username'] as String);
  }

  set username(String value) => values['username'] = value;
  String get password {
    return (values['password'] as String);
  }

  set password(String value) => values['password'] = value;
  String get email {
    return (values['email'] as String);
  }

  set email(String value) => values['email'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(User model) {
    username = model.username;
    password = model.password;
    email = model.email;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
  }
}

class RoleUserQuery extends Query<RoleUser, RoleUserQueryWhere> {
  RoleUserQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = new RoleUserQueryWhere(this);
    leftJoin('roles', 'role_id', 'id',
        additionalFields: const ['name', 'created_at', 'updated_at']);
    leftJoin('users', 'user_id', 'id', additionalFields: const [
      'username',
      'password',
      'email',
      'created_at',
      'updated_at'
    ]);
  }

  @override
  final RoleUserQueryValues values = new RoleUserQueryValues();

  RoleUserQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'role_users';
  }

  @override
  get fields {
    return const ['id', 'role_id', 'user_id', 'created_at', 'updated_at'];
  }

  @override
  RoleUserQueryWhere get where {
    return _where;
  }

  @override
  RoleUserQueryWhere newWhereClause() {
    return new RoleUserQueryWhere(this);
  }

  static RoleUser parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = new RoleUser(
        id: row[0].toString(),
        createdAt: (row[3] as DateTime),
        updatedAt: (row[4] as DateTime));
    if (row.length > 5) {
      model = model.copyWith(role: RoleQuery.parseRow(row.skip(5).toList()));
    }
    if (row.length > 9) {
      model = model.copyWith(user: UserQuery.parseRow(row.skip(9).toList()));
    }
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class RoleUserQueryWhere extends QueryWhere {
  RoleUserQueryWhere(RoleUserQuery query)
      : id = new NumericSqlExpressionBuilder<int>(query, 'id'),
        roleId = new NumericSqlExpressionBuilder<int>(query, 'role_id'),
        userId = new NumericSqlExpressionBuilder<int>(query, 'user_id'),
        createdAt = new DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = new DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final NumericSqlExpressionBuilder<int> roleId;

  final NumericSqlExpressionBuilder<int> userId;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  @override
  get expressionBuilders {
    return [id, roleId, userId, createdAt, updatedAt];
  }
}

class RoleUserQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  int get id {
    return (values['id'] as int);
  }

  set id(int value) => values['id'] = value;
  int get roleId {
    return (values['role_id'] as int);
  }

  set roleId(int value) => values['role_id'] = value;
  int get userId {
    return (values['user_id'] as int);
  }

  set userId(int value) => values['user_id'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(RoleUser model) {
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
    if (model.role != null) {
      values['role_id'] = int.parse(model.role.id);
    }
    if (model.user != null) {
      values['user_id'] = int.parse(model.user.id);
    }
  }
}

class RoleQuery extends Query<Role, RoleQueryWhere> {
  RoleQuery({Set<String> trampoline}) {
    trampoline ??= Set();
    trampoline.add(tableName);
    _where = new RoleQueryWhere(this);
  }

  @override
  final RoleQueryValues values = new RoleQueryValues();

  RoleQueryWhere _where;

  @override
  get casts {
    return {};
  }

  @override
  get tableName {
    return 'roles';
  }

  @override
  get fields {
    return const ['id', 'name', 'created_at', 'updated_at'];
  }

  @override
  RoleQueryWhere get where {
    return _where;
  }

  @override
  RoleQueryWhere newWhereClause() {
    return new RoleQueryWhere(this);
  }

  static Role parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = new Role(
        id: row[0].toString(),
        name: (row[1] as String),
        createdAt: (row[2] as DateTime),
        updatedAt: (row[3] as DateTime));
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }
}

class RoleQueryWhere extends QueryWhere {
  RoleQueryWhere(RoleQuery query)
      : id = new NumericSqlExpressionBuilder<int>(query, 'id'),
        name = new StringSqlExpressionBuilder(query, 'name'),
        createdAt = new DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = new DateTimeSqlExpressionBuilder(query, 'updated_at');

  final NumericSqlExpressionBuilder<int> id;

  final StringSqlExpressionBuilder name;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;

  @override
  get expressionBuilders {
    return [id, name, createdAt, updatedAt];
  }
}

class RoleQueryValues extends MapQueryValues {
  @override
  get casts {
    return {};
  }

  int get id {
    return (values['id'] as int);
  }

  set id(int value) => values['id'] = value;
  String get name {
    return (values['name'] as String);
  }

  set name(String value) => values['name'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Role model) {
    name = model.name;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
  }
}

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class User extends _User {
  User(
      {this.id,
      this.username,
      this.password,
      this.email,
      List<_Role> roles,
      this.createdAt,
      this.updatedAt})
      : this.roles = new List.unmodifiable(roles ?? []);

  @override
  final String id;

  @override
  final String username;

  @override
  final String password;

  @override
  final String email;

  @override
  final List<_Role> roles;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  User copyWith(
      {String id,
      String username,
      String password,
      String email,
      List<_Role> roles,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new User(
        id: id ?? this.id,
        username: username ?? this.username,
        password: password ?? this.password,
        email: email ?? this.email,
        roles: roles ?? this.roles,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _User &&
        other.id == id &&
        other.username == username &&
        other.password == password &&
        other.email == email &&
        const ListEquality<_Role>(const DefaultEquality<_Role>())
            .equals(other.roles, roles) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects(
        [id, username, password, email, roles, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return UserSerializer.toMap(this);
  }
}

@generatedSerializable
class RoleUser extends _RoleUser {
  RoleUser({this.id, this.role, this.user, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final _Role role;

  @override
  final _User user;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  RoleUser copyWith(
      {String id,
      _Role role,
      _User user,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new RoleUser(
        id: id ?? this.id,
        role: role ?? this.role,
        user: user ?? this.user,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _RoleUser &&
        other.id == id &&
        other.role == role &&
        other.user == user &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, role, user, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return RoleUserSerializer.toMap(this);
  }
}

@generatedSerializable
class Role extends _Role {
  Role({this.id, this.name, List<_User> users, this.createdAt, this.updatedAt})
      : this.users = new List.unmodifiable(users ?? []);

  @override
  final String id;

  @override
  final String name;

  @override
  final List<_User> users;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Role copyWith(
      {String id,
      String name,
      List<_User> users,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Role(
        id: id ?? this.id,
        name: name ?? this.name,
        users: users ?? this.users,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Role &&
        other.id == id &&
        other.name == name &&
        const ListEquality<_User>(const DefaultEquality<_User>())
            .equals(other.users, users) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, name, users, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return RoleSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class UserSerializer {
  static User fromMap(Map map) {
    return new User(
        id: map['id'] as String,
        username: map['username'] as String,
        password: map['password'] as String,
        email: map['email'] as String,
        roles: map['roles'] is Iterable
            ? new List.unmodifiable(((map['roles'] as Iterable)
                    .where((x) => x is Map) as Iterable<Map>)
                .map(RoleSerializer.fromMap))
            : null,
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at'].toString()))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at'].toString()))
            : null);
  }

  static Map<String, dynamic> toMap(_User model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'username': model.username,
      'password': model.password,
      'email': model.email,
      'roles': model.roles?.map((m) => RoleSerializer.toMap(m))?.toList(),
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class UserFields {
  static const List<String> allFields = const <String>[
    id,
    username,
    password,
    email,
    roles,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String username = 'username';

  static const String password = 'password';

  static const String email = 'email';

  static const String roles = 'roles';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}

abstract class RoleUserSerializer {
  static RoleUser fromMap(Map map) {
    return new RoleUser(
        id: map['id'] as String,
        role: map['role'] != null
            ? RoleSerializer.fromMap(map['role'] as Map)
            : null,
        user: map['user'] != null
            ? UserSerializer.fromMap(map['user'] as Map)
            : null,
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at'].toString()))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at'].toString()))
            : null);
  }

  static Map<String, dynamic> toMap(_RoleUser model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'role': RoleSerializer.toMap(model.role),
      'user': UserSerializer.toMap(model.user),
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class RoleUserFields {
  static const List<String> allFields = const <String>[
    id,
    role,
    user,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String role = 'role';

  static const String user = 'user';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}

abstract class RoleSerializer {
  static Role fromMap(Map map) {
    return new Role(
        id: map['id'] as String,
        name: map['name'] as String,
        users: map['users'] is Iterable
            ? new List.unmodifiable(((map['users'] as Iterable)
                    .where((x) => x is Map) as Iterable<Map>)
                .map(UserSerializer.fromMap))
            : null,
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at'].toString()))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at'].toString()))
            : null);
  }

  static Map<String, dynamic> toMap(_Role model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'name': model.name,
      'users': model.users?.map((m) => UserSerializer.toMap(m))?.toList(),
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class RoleFields {
  static const List<String> allFields = const <String>[
    id,
    name,
    users,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String name = 'name';

  static const String users = 'users';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
