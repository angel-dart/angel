import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mongo/angel_mongo.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:json_god/json_god.dart' as god;
import 'package:mongo_dart/mongo_dart.dart';
import 'schema.dart';

@god.WithSchema(UserSchema)
class User extends Model {
  String email;
  String username;
  String password;
  List<String> roles;

  User(
      {String this.email,
      String this.username,
      String this.password,
      List<String> roles}) {
    this.roles = roles ?? [];
  }
}

hashPassword(HookedServiceEvent event) {
  if (event.data.password != null) {
    event.data.password =
        sha256.convert(event.data.password.codeUnits).toString();
  }
}

configureServer(Db db) {
  return (Angel app) async {
    app.use("/api/users", new MongoTypedService<User>(db.collection("users")));

    HookedService service = app.service("api/users");

    // Place your hooks here!
    service.beforeCreated.listen(hashPassword);
  };
}
