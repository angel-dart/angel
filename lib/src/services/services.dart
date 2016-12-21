/// Declare services here!
library angel.services;

import 'package:angel_common/angel_common.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'user.dart' as User;

configureServer(Angel app) async {
  Db db = new Db(app.mongo_db);
  await db.open();

  await app.configure(User.configureServer(db));
}
