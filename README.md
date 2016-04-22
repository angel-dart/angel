# Angel Configuration
YAML configuration loader for Angel.

# About
Any web app needs different configuration for development and production. This plugin will search
for a `config/default.yaml` file. If it is found, configuratiom from it is loaded into `angel.properties`.
Then, it will look for a `config/$ANGEL_ENV` file. (i.e. config/development.yaml). If this found, all of its
configuration be loaded, and will override anything loaded from the `default.yaml` file. This allows for your
app to work under different conditions without you re-coding anything. :)

# Installation
In `pubspec.yaml`:

    dependencies:
        angel_framework: ^0.0.0-dev
        angel_static: ^1.0.0-beta

# Usage

```dart
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_configuration/angel_configuration.dart';

main() async {
    Angel angel = new Angel();
    angel.configure(loadConfigurationFile()); // It's that easy
}
```

`loadConfigurationFile` also accepts a `sourceDirectory` or `overrideEnvironmentName` parameter.
The former will allow you to search in a directory other than `config`, and the latter lets you
override `$ANGEL_ENV` by specifying a specific configuration name to look for (i.e. 'production').