/// Declare services here!
library angel.services;

import 'package:angel_common/angel_common.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'user.dart' as user;

configureServer(Angel app) async {
  Db db = app.container.make(Db);

  await app.configure(user.configureServer(db));
}
