library angel_configuration;

import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:merge_map/merge_map.dart';
import 'package:yaml/yaml.dart';

final RegExp _equ = new RegExp(r'=$');
final RegExp _sym = new RegExp(r'Symbol\("([^"]+)"\)');

/// A proxy object that encapsulates a server's configuration.
@proxy
class Configuration {
  /// The [Angel] instance that loaded this configuration.
  final Angel app;
  Configuration(this.app);

  operator [](key) => app.properties[key];
  operator []=(key, value) => app.properties[key] = value;

  noSuchMethod(Invocation invocation) {
    if (invocation.memberName != null) {
      String name = _sym.firstMatch(invocation.memberName.toString()).group(1);

      if (invocation.isMethod) {
        return Function.apply(app.properties[name],
            invocation.positionalArguments, invocation.namedArguments);
      } else if (invocation.isGetter) {
        return app.properties[name];
      }
    }

    super.noSuchMethod(invocation);
  }
}

_loadYamlFile(Angel app, File yamlFile, Map<String, String> env) async {
  if (await yamlFile.exists()) {
    var config = loadYaml(await yamlFile.readAsString());
    if (config is! Map) {
      stderr.writeln(
          'WARNING: The configuration at "${yamlFile.absolute.path}" is not a Map. Refusing to load it.');
      return;
    }

    Map<String, dynamic> out = {};

    for (String key in config.keys) {
      out[key] = _applyEnv(config[key], env ?? {});
    }

    app.properties.addAll(mergeMap(
      [
        app.properties,
        out,
      ],
      acceptNull: true,
    ));
  }
}

_applyEnv(var v, Map<String, String> env) {
  if (v is String) {
    if (v.startsWith(r'$') && v.length > 1) {
      var key = v.substring(1);
      if (env.containsKey(key))
        return env[key];
      else {
        stderr.writeln(
            'Your configuration calls for loading the value of "$key" from the system environment, but it is not defined. Defaulting to `null`.');
        return null;
      }
    } else
      return v;
  } else if (v is Iterable) {
    return v.map((x) => _applyEnv(x, env ?? {})).toList();
  } else if (v is Map) {
    return v.keys
        .fold<Map>({}, (out, k) => out..[k] = _applyEnv(v[k], env ?? {}));
  } else
    return v;
}

/// Dynamically loads application configuration from configuration files.
///
/// You can modify which [directoryPath] to search in, or explicitly
/// load from a [overrideEnvironmentName].
///
/// You can also specify a custom [envPath] to load system configuration from.
AngelConfigurer loadConfigurationFile(
    {String directoryPath: "./config",
    String overrideEnvironmentName,
    String envPath}) {
  return (Angel app) async {
    Directory sourceDirectory = new Directory(directoryPath);
    var env = dotenv.env;
    var envFile =
        new File.fromUri(sourceDirectory.uri.resolve(envPath ?? '.env'));

    if (await envFile.exists()) {
      try {
        dotenv.load(envFile.absolute.uri.toFilePath());
      } catch (_) {
        stderr.writeln(
            'WARNING: Found an environment configuration at ${envFile.absolute.path}, but it was invalidly formatted. Refusing to load it.');
      }
    }

    String environmentName = env['ANGEL_ENV'] ?? 'development';

    if (overrideEnvironmentName != null) {
      environmentName = overrideEnvironmentName;
    }

    File defaultYaml =
        new File.fromUri(sourceDirectory.absolute.uri.resolve("default.yaml"));
    await _loadYamlFile(app, defaultYaml, env);

    String configFilePath = "$environmentName.yaml";
    File configFile =
        new File.fromUri(sourceDirectory.absolute.uri.resolve(configFilePath));

    await _loadYamlFile(app, configFile, env);
    app.container.singleton(new Configuration(app));
  };
}
