/// Configuration for this Angel instance.
library angel.config;

import 'dart:io';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_configuration/angel_configuration.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mustache/angel_mustache.dart';

/// This is a perfect place to include configuration and load plug-ins.
configureServer(Angel app) async {
  AngelAuthOptions localOpts = new AngelAuthOptions(
      failureRedirect: '/failure', successRedirect: '/success');
  Map sampleUser = {'hello': 'world'};

  verifier(username, password) async {
    if (username == 'username' && password == 'password') {
      return sampleUser;
    } else
      return false;
  }

  wireAuth(Angel app) async {
    Auth.serializer = (user) async => 1337;
    Auth.deserializer = (id) async => sampleUser;

    Auth.strategies.add(new LocalAuthStrategy(verifier));
    await app.configure(AngelAuth);
  }
  await app.configure(loadConfigurationFile());
  await app.configure(mustache(new Directory('views')));
}
