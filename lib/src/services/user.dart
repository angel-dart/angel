import 'package:angel_common/angel_common.dart';
import 'package:angel_framework/hooks.dart' as hooks;
import 'package:crypto/crypto.dart' show sha256;
import 'package:random_string/random_string.dart' as rs;
import '../models/user.dart';
import '../validators/user.dart';
export '../models/user.dart';

/// Sets up a service mounted at `api/users`.
///
/// In the real world, you will want to hook this up to a database.
/// However, for the sake of the boilerplate, an in-memory service is used,
/// so that users are not tied into using just one database. :)
configureServer() {
  return (Angel app) async {
    // A TypedService can be used to serialize and deserialize data to a class, somewhat like an ORM.
    //
    // See here: https://github.com/angel-dart/angel/wiki/TypedService
    app.use('/api/users', new TypedService<User>(new MapService()));

    // Configure hooks for the user service.
    // Hooks can be used to add additional functionality, or change the behavior
    // of services, and run on any service, regardless of which database you are using.
    //
    // If you have not already, *definitely* read the service hook documentation:
    // https://github.com/angel-dart/angel/wiki/Hooks

    var service = app.service('api/users') as HookedService;

    // Prevent clients from doing anything to the `users` service,
    // apart from reading a single user's data.
    service.before([
      HookedServiceEvent.INDEXED,
      HookedServiceEvent.CREATED,
      HookedServiceEvent.MODIFIED,
      HookedServiceEvent.UPDATED,
      HookedServiceEvent.REMOVED
    ], hooks.disable());

    // Validate new users, and also hash their passwords.
    service.beforeCreated
      // ..listen(validateEvent(CREATE_USER))
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
