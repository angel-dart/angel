/// Configuration for this Angel instance.
library angel.config;

import 'dart:io';
import 'package:angel_common/angel_common.dart';
// import 'package:angel_multiserver/angel_multiserver.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'plugins/plugins.dart' as plugins;

/// This is a perfect place to include configuration and load plug-ins.
configureServer(Angel app) async {

  await app.configure(loadConfigurationFile());
  var db = new Db(app.mongo_db);
  await db.open();
  app.container.singleton(db);

  await app.configure(mustache(new Directory('views')));
  await plugins.configureServer(app);


  // Uncomment this to enable session synchronization across instances.
  // This will add the overhead of querying a database at the beginning
  // and end of every request. Thus, it should only be activated if necessary.
  //
  // For applications of scale, it is better to steer clear of session use
  // entirely.
  // await app.configure(new MongoSessionSynchronizer(db.collection('sessions')));
}
