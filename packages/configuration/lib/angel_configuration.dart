library angel_configuration;

import 'dart:async';

import 'package:angel_framework/angel_framework.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:file/file.dart';
import 'package:merge_map/merge_map.dart';
import 'package:yaml/yaml.dart';

Future<void> _loadYamlFile(Map map, File yamlFile, Map<String, String> env,
    void Function(String msg) warn) async {
  if (await yamlFile.exists()) {
    var config = loadYaml(await yamlFile.readAsString());

    if (config is! Map) {
      warn(
          'The configuration at "${yamlFile.absolute.path}" is not a Map. Refusing to load it.');
      return;
    }

    var out = {};

    var configMap = Map.of(config as Map);

    // Check for _include
    if (configMap.containsKey('_include')) {
      var include = configMap.remove('_include');
      var includeList = include is Iterable ? include.toList() : [include];
      for (var inc in includeList) {
        if (inc is! String) {
          warn('Included item $inc is not a String.');
        } else {
          var p = yamlFile.fileSystem.path;
          var includeFilePath = p.join(yamlFile.parent.path, inc);
          var includeFile = yamlFile.fileSystem.file(includeFilePath);
          if (!await includeFile.exists()) {
            warn(
                'Included configuration file "$includeFilePath" does not exist.');
          } else {
            await _loadYamlFile(out, includeFile, env, warn);
          }
        }
      }
    }

    for (String key in configMap.keys) {
      out[key] = _applyEnv(configMap[key], env ?? {}, warn);
    }

    map.addAll(mergeMap(
      [
        map,
        out,
      ],
      acceptNull: true,
    ));
  }
}

Object _applyEnv(
    var v, Map<String, String> env, void Function(String msg) warn) {
  if (v is String) {
    if (v.startsWith(r'$') && v.length > 1) {
      var key = v.substring(1);
      if (env.containsKey(key)) {
        return env[key];
      } else {
        warn(
            'Your configuration calls for loading the value of "$key" from the system environment, but it is not defined. Defaulting to `null`.');
        return null;
      }
    } else {
      return v;
    }
  } else if (v is Iterable) {
    return v.map((x) => _applyEnv(x, env ?? {}, warn)).toList();
  } else if (v is Map) {
    return v.keys
        .fold<Map>({}, (out, k) => out..[k] = _applyEnv(v[k], env ?? {}, warn));
  } else {
    return v;
  }
}

/// Loads [configuration], and returns a [Map].
///
/// You can override [onWarning]; otherwise, configuration errors will throw.
Future<Map> loadStandaloneConfiguration(FileSystem fileSystem,
    {String directoryPath = './config',
    String overrideEnvironmentName,
    String envPath,
    void Function(String message) onWarning}) async {
  var sourceDirectory = fileSystem.directory(directoryPath);
  var env = dotenv.env;
  var envFile = sourceDirectory.childFile(envPath ?? '.env');

  if (await envFile.exists()) {
    dotenv.load(envFile.absolute.uri.toFilePath());
  }

  var environmentName = env['ANGEL_ENV'] ?? 'development';

  if (overrideEnvironmentName != null) {
    environmentName = overrideEnvironmentName;
  }

  onWarning ??= (String message) => throw StateError(message);
  var out = {};

  var defaultYaml = sourceDirectory.childFile('default.yaml');
  await _loadYamlFile(out, defaultYaml, env, onWarning);

  var configFilePath = '$environmentName.yaml';
  var configFile = sourceDirectory.childFile(configFilePath);

  await _loadYamlFile(out, configFile, env, onWarning);

  return out;
}

/// Dynamically loads application configuration from configuration files.
///
/// You can modify which [directoryPath] to search in, or explicitly
/// load from a [overrideEnvironmentName].
///
/// You can also specify a custom [envPath] to load system configuration from.
AngelConfigurer configuration(FileSystem fileSystem,
    {String directoryPath = './config',
    String overrideEnvironmentName,
    String envPath}) {
  return (Angel app) async {
    var config = await loadStandaloneConfiguration(
      fileSystem,
      directoryPath: directoryPath,
      overrideEnvironmentName: overrideEnvironmentName,
      envPath: envPath,
      onWarning: app.logger == null
          ? null
          : (msg) => app.logger?.warning('WARNING: $msg'),
    );
    app.configuration.addAll(mergeMap(
      [
        app.configuration,
        config,
      ],
      acceptNull: true,
    ));
  };
}
