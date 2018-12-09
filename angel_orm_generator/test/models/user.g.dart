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

class UserRoleMigration extends Migration {
  @override
  up(Schema schema) {
    schema.create('user_roles', (table) {
      table.serial('id')..primaryKey();
      table.integer('user_id').references('users', 'id');
      table.integer('role_id').references('roles', 'id');
    });
  }

  @override
  down(Schema schema) {
    schema.drop('user_roles');
  }
}

// **************************************************************************
// OrmGenerator
// **************************************************************************

class UserQuery extends Query<User, UserQueryWhere> {
  UserQuery() {}

  @override
  final UserQueryValues values = new UserQueryValues();

  @override
  final UserQueryWhere where = new UserQueryWhere();

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
  UserQueryWhere newWhereClause() {
    return new UserQueryWhere();
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

  @override
  insert(executor) {
    return executor.transaction(() async {
      var result = await super.insert(executor);
      where.id.equals(int.parse(result.id));
      result = await getOne(executor);
      result = await fetchLinked(result, executor);
      return result;
    });
  }

  Future<User> fetchLinked(User model, QueryExecutor executor) async {
    return model.copyWith(
        userRoles: await (new UserRoleQuery()
              ..where.userId.equals(int.parse(model.id)))
            .get(executor));
  }

  @override
  get(QueryExecutor executor) {
    return executor.transaction(() async {
      var result = await super.get(executor);
      return await Future.wait(result.map((m) => fetchLinked(m, executor)));
    });
  }

  @override
  update(QueryExecutor executor) {
    return executor.transaction(() async {
      var result = await super.update(executor);
      return await Future.wait(result.map((m) => fetchLinked(m, executor)));
    });
  }

  @override
  delete(QueryExecutor executor) {
    return executor.transaction(() async {
      var result = await super.delete(executor);
      return await Future.wait(result.map((m) => fetchLinked(m, executor)));
    });
  }
}

class UserQueryWhere extends QueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>('id');

  final StringSqlExpressionBuilder username =
      new StringSqlExpressionBuilder('username');

  final StringSqlExpressionBuilder password =
      new StringSqlExpressionBuilder('password');

  final StringSqlExpressionBuilder email =
      new StringSqlExpressionBuilder('email');

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('updated_at');

  @override
  get expressionBuilders {
    return [id, username, password, email, createdAt, updatedAt];
  }
}

class UserQueryValues extends MapQueryValues {
  int get id {
    return (values['id'] as int);
  }

  void set id(int value) => values['id'] = value;
  String get username {
    return (values['username'] as String);
  }

  void set username(String value) => values['username'] = value;
  String get password {
    return (values['password'] as String);
  }

  void set password(String value) => values['password'] = value;
  String get email {
    return (values['email'] as String);
  }

  void set email(String value) => values['email'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  void set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  void set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(User model) {
    values.addAll({
      'username': model.username,
      'password': model.password,
      'email': model.email,
      'created_at': model.createdAt,
      'updated_at': model.updatedAt
    });
  }
}

class RoleQuery extends Query<Role, RoleQueryWhere> {
  RoleQuery() {}

  @override
  final RoleQueryValues values = new RoleQueryValues();

  @override
  final RoleQueryWhere where = new RoleQueryWhere();

  @override
  get tableName {
    return 'roles';
  }

  @override
  get fields {
    return const ['id', 'name', 'created_at', 'updated_at'];
  }

  @override
  RoleQueryWhere newWhereClause() {
    return new RoleQueryWhere();
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

  @override
  insert(executor) {
    return executor.transaction(() async {
      var result = await super.insert(executor);
      where.id.equals(int.parse(result.id));
      result = await getOne(executor);
      result = await fetchLinked(result, executor);
      return result;
    });
  }

  Future<Role> fetchLinked(Role model, QueryExecutor executor) async {
    return model.copyWith(
        userRoles: await (new UserRoleQuery()
              ..where.roleId.equals(int.parse(model.id)))
            .get(executor));
  }

  @override
  get(QueryExecutor executor) {
    return executor.transaction(() async {
      var result = await super.get(executor);
      return await Future.wait(result.map((m) => fetchLinked(m, executor)));
    });
  }

  @override
  update(QueryExecutor executor) {
    return executor.transaction(() async {
      var result = await super.update(executor);
      return await Future.wait(result.map((m) => fetchLinked(m, executor)));
    });
  }

  @override
  delete(QueryExecutor executor) {
    return executor.transaction(() async {
      var result = await super.delete(executor);
      return await Future.wait(result.map((m) => fetchLinked(m, executor)));
    });
  }
}

class RoleQueryWhere extends QueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>('id');

  final StringSqlExpressionBuilder name =
      new StringSqlExpressionBuilder('name');

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('updated_at');

  @override
  get expressionBuilders {
    return [id, name, createdAt, updatedAt];
  }
}

class RoleQueryValues extends MapQueryValues {
  int get id {
    return (values['id'] as int);
  }

  void set id(int value) => values['id'] = value;
  String get name {
    return (values['name'] as String);
  }

  void set name(String value) => values['name'] = value;
  DateTime get createdAt {
    return (values['created_at'] as DateTime);
  }

  void set createdAt(DateTime value) => values['created_at'] = value;
  DateTime get updatedAt {
    return (values['updated_at'] as DateTime);
  }

  void set updatedAt(DateTime value) => values['updated_at'] = value;
  void copyFrom(Role model) {
    values.addAll({
      'name': model.name,
      'created_at': model.createdAt,
      'updated_at': model.updatedAt
    });
  }
}

class UserRoleQuery extends Query<UserRole, UserRoleQueryWhere> {
  UserRoleQuery() {
    leftJoin('users', 'user_id', 'id', additionalFields: const [
      'username',
      'password',
      'email',
      'created_at',
      'updated_at'
    ]);
    leftJoin('roles', 'role_id', 'id',
        additionalFields: const ['name', 'created_at', 'updated_at']);
  }

  @override
  final UserRoleQueryValues values = new UserRoleQueryValues();

  @override
  final UserRoleQueryWhere where = new UserRoleQueryWhere();

  @override
  get tableName {
    return 'user_roles';
  }

  @override
  get fields {
    return const ['id', 'user_id', 'role_id'];
  }

  @override
  UserRoleQueryWhere newWhereClause() {
    return new UserRoleQueryWhere();
  }

  static UserRole parseRow(List row) {
    if (row.every((x) => x == null)) return null;
    var model = new UserRole(id: (row[0] as int));
    if (row.length > 3) {
      model = model.copyWith(user: UserQuery.parseRow(row.skip(3).toList()));
    }
    if (row.length > 9) {
      model = model.copyWith(role: RoleQuery.parseRow(row.skip(9).toList()));
    }
    return model;
  }

  @override
  deserialize(List row) {
    return parseRow(row);
  }

  @override
  insert(executor) {
    return executor.transaction(() async {
      var result = await super.insert(executor);
      return result;
    });
  }
}

class UserRoleQueryWhere extends QueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>('id');

  final NumericSqlExpressionBuilder<int> userId =
      new NumericSqlExpressionBuilder<int>('user_id');

  final NumericSqlExpressionBuilder<int> roleId =
      new NumericSqlExpressionBuilder<int>('role_id');

  @override
  get expressionBuilders {
    return [id, userId, roleId];
  }
}

class UserRoleQueryValues extends MapQueryValues {
  int get id {
    return (values['id'] as int);
  }

  void set id(int value) => values['id'] = value;
  int get userId {
    return (values['user_id'] as int);
  }

  void set userId(int value) => values['user_id'] = value;
  int get roleId {
    return (values['role_id'] as int);
  }

  void set roleId(int value) => values['role_id'] = value;
  void copyFrom(UserRole model) {
    values.addAll({'id': model.id});
    if (model.user != null) {
      values['user_id'] = int.parse(model.user.id);
    }
    if (model.role != null) {
      values['role_id'] = int.parse(model.role.id);
    }
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
      List<_UserRole> userRoles,
      this.createdAt,
      this.updatedAt})
      : this.userRoles = new List.unmodifiable(userRoles ?? []);

  @override
  final String id;

  @override
  final String username;

  @override
  final String password;

  @override
  final String email;

  @override
  final List<_UserRole> userRoles;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  User copyWith(
      {String id,
      String username,
      String password,
      String email,
      List<_UserRole> userRoles,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new User(
        id: id ?? this.id,
        username: username ?? this.username,
        password: password ?? this.password,
        email: email ?? this.email,
        userRoles: userRoles ?? this.userRoles,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _User &&
        other.id == id &&
        other.username == username &&
        other.password == password &&
        other.email == email &&
        const ListEquality<_UserRole>(const DefaultEquality<_UserRole>())
            .equals(other.userRoles, userRoles) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects(
        [id, username, password, email, userRoles, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return UserSerializer.toMap(this);
  }
}

@generatedSerializable
class Role extends _Role {
  Role(
      {this.id,
      this.name,
      List<_UserRole> userRoles,
      this.createdAt,
      this.updatedAt})
      : this.userRoles = new List.unmodifiable(userRoles ?? []);

  @override
  final String id;

  @override
  final String name;

  @override
  final List<_UserRole> userRoles;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Role copyWith(
      {String id,
      String name,
      List<_UserRole> userRoles,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Role(
        id: id ?? this.id,
        name: name ?? this.name,
        userRoles: userRoles ?? this.userRoles,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Role &&
        other.id == id &&
        other.name == name &&
        const ListEquality<_UserRole>(const DefaultEquality<_UserRole>())
            .equals(other.userRoles, userRoles) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, name, userRoles, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return RoleSerializer.toMap(this);
  }
}

@generatedSerializable
class UserRole implements _UserRole {
  const UserRole({this.id, this.user, this.role});

  @override
  final int id;

  @override
  final _User user;

  @override
  final _Role role;

  UserRole copyWith({int id, _User user, _Role role}) {
    return new UserRole(
        id: id ?? this.id, user: user ?? this.user, role: role ?? this.role);
  }

  bool operator ==(other) {
    return other is _UserRole &&
        other.id == id &&
        other.user == user &&
        other.role == role;
  }

  @override
  int get hashCode {
    return hashObjects([id, user, role]);
  }

  Map<String, dynamic> toJson() {
    return UserRoleSerializer.toMap(this);
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
        userRoles: map['user_roles'] is Iterable
            ? new List.unmodifiable(((map['user_roles'] as Iterable)
                    .where((x) => x is Map) as Iterable<Map>)
                .map(UserRoleSerializer.fromMap))
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
      'user_roles':
          model.userRoles?.map((m) => UserRoleSerializer.toMap(m))?.toList(),
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
    userRoles,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String username = 'username';

  static const String password = 'password';

  static const String email = 'email';

  static const String userRoles = 'user_roles';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}

abstract class RoleSerializer {
  static Role fromMap(Map map) {
    return new Role(
        id: map['id'] as String,
        name: map['name'] as String,
        userRoles: map['user_roles'] is Iterable
            ? new List.unmodifiable(((map['user_roles'] as Iterable)
                    .where((x) => x is Map) as Iterable<Map>)
                .map(UserRoleSerializer.fromMap))
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
      'user_roles':
          model.userRoles?.map((m) => UserRoleSerializer.toMap(m))?.toList(),
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class RoleFields {
  static const List<String> allFields = const <String>[
    id,
    name,
    userRoles,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String name = 'name';

  static const String userRoles = 'user_roles';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}

abstract class UserRoleSerializer {
  static UserRole fromMap(Map map) {
    return new UserRole(
        id: map['id'] as int,
        user: map['user'] != null
            ? UserSerializer.fromMap(map['user'] as Map)
            : null,
        role: map['role'] != null
            ? RoleSerializer.fromMap(map['role'] as Map)
            : null);
  }

  static Map<String, dynamic> toMap(_UserRole model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'user': UserSerializer.toMap(model.user),
      'role': RoleSerializer.toMap(model.role)
    };
  }
}

abstract class UserRoleFields {
  static const List<String> allFields = const <String>[id, user, role];

  static const String id = 'id';

  static const String user = 'user';

  static const String role = 'role';
}
