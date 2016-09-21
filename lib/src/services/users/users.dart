import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mongo/angel_mongo.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:validate/validate.dart';
import '../../models/user.dart';


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

    service.beforeCreated.listen((HookedServiceEvent e) {
      Validate.isKeyInMap("username", e.data);
      Validate.isEmail(e.data["email"]);
      Validate.isPassword(e.data["password"]);
    });

    service.beforeCreated.listen(hashPassword);
  };
}
