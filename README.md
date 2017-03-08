# Angel Configuration

![version 1.0.3](https://img.shields.io/badge/version-1.0.3-brightgreen.svg)
![build status](https://travis-ci.org/angel-dart/configuration.svg)

Isomorphic YAML configuration loader for Angel.

# About
Any web app needs different configuration for development and production. This plugin will search
for a `config/default.yaml` file. If it is found, configuration from it is loaded into `angel.properties`.
Then, it will look for a `config/$ANGEL_ENV` file. (i.e. config/development.yaml). If this found, all of its
configuration be loaded, and will override anything loaded from the `default.yaml` file. This allows for your
app to work under different conditions without you re-coding anything. :)

# Installation
In `pubspec.yaml`:

```yaml
dependencies:
    angel_configuration: ^1.0.0
```

# Usage

**Server-side**

```dart
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_configuration/angel_configuration.dart';

main() async {
    Angel angel = new Angel();
    angel.configure(loadConfigurationFile()); // It's that easy!
    
    app.get('/foo', (Configuration config) {
      return config.some_key;
    });
}
```

`loadConfigurationFile` also accepts a `sourceDirectory` or `overrideEnvironmentName` parameter.
The former will allow you to search in a directory other than `config`, and the latter lets you
override `$ANGEL_ENV` by specifying a specific configuration name to look for (i.e. 'production').

**In the Browser**

You can easily load configuration values within your client-side app,
and they will be automatically replaced by a Barback transformer.

In your `pubspec.yaml`:

```yaml
transformers:
- angel_configuration
```

In your app:

```dart
import 'package:angel_configuration/browser.dart';

main() async {
    print(config("some_key.other.nested_key"));
}
```

You can also provide a `dir` or `env` argument, corresponding to
the ones on the server-side.
