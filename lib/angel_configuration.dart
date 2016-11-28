library angel_configuration;

import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_route/src/extensible.dart';
import 'package:yaml/yaml.dart';

final RegExp _equ = new RegExp(r'=$');
final RegExp _sym = new RegExp(r'Symbol\("([^"]+)"\)');

@proxy
class Configuration {
  final Angel app;
  Configuration(this.app);

  operator [](key) => app.properties[key];
  operator []=(key, value) => app.properties[key] = value;

  noSuchMethod(Invocation invocation) {
    if (invocation.memberName != null) {
      String name = _sym.firstMatch(invocation.memberName.toString()).group(1);

      if (invocation.isMethod) {
        return Function.apply(app.properties[name], invocation.positionalArguments,
            invocation.namedArguments);
      } else if (invocation.isGetter) {
        return app.properties[name];
      }
    }

    super.noSuchMethod(invocation);
  }
}

_loadYamlFile(Angel app, File yamlFile) async {
  if (await yamlFile.exists()) {
    Map config = loadYaml(await yamlFile.readAsString());
    for (String key in config.keys) {
      app.properties[key] = config[key];
    }
  }
}

loadConfigurationFile(
    {String directoryPath: "./config", String overrideEnvironmentName}) {
  return (Angel app) async {
    Directory sourceDirectory = new Directory(directoryPath);
    String environmentName = Platform.environment['ANGEL_ENV'] ?? 'development';

    if (overrideEnvironmentName != null) {
      environmentName = overrideEnvironmentName;
    }

    File defaultYaml = new File.fromUri(
        sourceDirectory.absolute.uri.resolve("default.yaml"));
    await _loadYamlFile(app, defaultYaml);

    String configFilePath = "$environmentName.yaml";
    File configFile = new File.fromUri(
        sourceDirectory.absolute.uri.resolve(configFilePath));

    await _loadYamlFile(app, configFile);
    app.container.singleton(new Configuration(app));
  };
}