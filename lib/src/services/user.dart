import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mongo/angel_mongo.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:validate/validate.dart';
import '../models/user.dart';
export '../models/user.dart';

configureServer(Db db) {
  return (Angel app) async {
    app.use("/api/users", new UserService(db.collection("users")));

    HookedService service = app.service("api/users");
    app.container.singleton(service.inner);
  };
}

/// SHA-256 hash any string, particularly a password.
String hashPassword(String password) =>
    sha256.convert(password.codeUnits).toString();

/// Manages users.
///
/// Here, we extended the base service class. This allows to only expose
/// specific methods, and also allows more freedom over things such as validation.
class UserService extends Service {
  MongoTypedService<User> _inner;

  UserService(DbCollection collection) : super() {
    _inner = new MongoTypedService<User>(collection);
  }

  @override
  index([Map params]) {
    if (params != null && params.containsKey("provider")) {
      // Nobody needs to see the entire user list except for the server.
      throw new AngelHttpException.Forbidden();
    }

    return _inner.index(params);
  }

  @override
  create(data, [Map params]) {
    if (params != null && params.containsKey("provider")) {
      // Deny creating users to the public - this should be done by the server only.
      throw new AngelHttpException.Forbidden();
    }

    try {
      Validate.isKeyInMap("username", data);
      Validate.isKeyInMap("password", data);
      Validate.isEmail(data["email"]);
      data["password"] = hashPassword(data["password"]);
    } catch (e) {
      throw new AngelHttpException.BadRequest(
          message: "User must have a username, e-mail address and password.");
    }

    return _inner.create(data, params);
  }

  @override
  read(id, [Map params]) => _inner.read(id, params);
}
