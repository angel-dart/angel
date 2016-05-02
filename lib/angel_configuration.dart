library angel_configuration;

import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:yaml/yaml.dart';

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
  };
}