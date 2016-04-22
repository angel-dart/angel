library angel_configuration;

import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:yaml/yaml.dart';

_loadYamlFile(Angel app, File yamlFile) {
  if (yamlFile.existsSync()) {
    Map config = loadYaml(yamlFile.readAsStringSync());
    for (String key in config.keys) {
      app.properties[key] = config[key];
    }
  }
}

loadConfigurationFile(
    {String directoryPath: "./config", String overrideEnvironmentName}) {
  return (Angel app) {
    Directory sourceDirectory = new Directory(directoryPath);
    String environmentName = Platform.environment['ANGEL_ENV'] ?? 'development';

    if (overrideEnvironmentName != null) {
      environmentName = overrideEnvironmentName;
    }

    File defaultYaml = new File.fromUri(
        sourceDirectory.absolute.uri.resolve("default.yaml"));
    _loadYamlFile(app, defaultYaml);

    String configFilePath = "$environmentName.yaml";
    File configFile = new File.fromUri(
        sourceDirectory.absolute.uri.resolve(configFilePath));

    _loadYamlFile(app, configFile);
  };
}