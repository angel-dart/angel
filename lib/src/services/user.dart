import 'package:angel_common/angel_common.dart';
import 'package:angel_framework/hooks.dart' as hooks;
import 'package:crypto/crypto.dart' show sha256;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:random_string/random_string.dart' as rs;
import '../models/user.dart';
import '../validators/user.dart';
export '../models/user.dart';

configureServer(Db db) {
  return (Angel app) async {
    app.use('/api/users',
        new TypedService<User>(new MongoService(db.collection('users'))));

    HookedService service = app.service('api/users');

    // Prevent clients from doing anything to the `users` service,
    // apart from reading a single user's data.
    service.before([
      HookedServiceEvent.INDEXED,
      HookedServiceEvent.CREATED,
      HookedServiceEvent.MODIFIED,
      HookedServiceEvent.UPDATED,
      HookedServiceEvent.REMOVED
    ], hooks.disable());
    
    // Don't broadcast user events over WebSockets - they're sensitive data!
    service.beforeAll((e) {
      e.params['broadcast'] = false;
    });

    // Validate new users, and also hash their passwords.
    service.beforeCreated
      ..listen(validateEvent(CREATE_USER))
      ..listen((e) {
        var salt = rs.randomAlphaNumeric(12);
        e.data
          ..['password'] =
              hashPassword(e.data['password'], salt, app.jwt_secret)
          ..['salt'] = salt;
      });

    // Remove sensitive data from serialized JSON.
    service.afterAll(hooks.remove(['password', 'salt']));
  };
}

/// SHA-256 hash any string, particularly a password.
String hashPassword(String password, String salt, String pepper) =>
    sha256.convert(('$salt:$password:$pepper').codeUnits).toString();
