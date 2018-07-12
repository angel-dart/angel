# configuration

[![Pub](https://img.shields.io/pub/v/angel_configuration.svg)](https://pub.dartlang.org/packages/angel_configuration)
[![build status](https://travis-ci.org/angel-dart/configuration.svg)](https://travis-ci.org/angel-dart/configuration)

Automatic YAML configuration loader for Angel.

# About
Any web app needs different configuration for development and production. This plugin will search
for a `config/default.yaml` file. If it is found, configuration from it is loaded into `app.configuration`.
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

**Example Configuration**
```yaml
# Define normal YAML objects
some_key: foo
this_is_a_map:
  a_string: "string"
  another_string: "string"
  
```

You can also load configuration from the environment:
```yaml
# Loaded from the environment
system_path: $PATH
```

If a `.env` file is present in your configuration directory, then it will be loaded before
applying YAML configuration.

**Server-side**
Call `configuration()`. The loaded configuration will be available in your application's
`configuration` map, which means you can access them like normal instance members.

```dart
main() {
  print(app.foo == app.configuration['foo']); // true
}
```

An instance of `Configuration` will also be injected to your application, and it works
the same way:

```dart
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_configuration/angel_configuration.dart';
import 'package:file/local.dart';

main() async {
    var app = new Angel();
    var fileSystem = const LocalFileSystem();
    
    await app.configure(configuration(fileSystem)); // It's that easy!
    
    app.get('/foo', (Configuration config) {
      return config.some_key;
    });
}
```

`configuration` also accepts a `sourceDirectory` or `overrideEnvironmentName` parameter.
The former will allow you to search in a directory other than `config`, and the latter lets you
override `$ANGEL_ENV` by specifying a specific configuration name to look for (i.e. `production`).

This package uses
[`package:merge_map`](https://github.com/thosakwe/merge_map)
internally, so existing configurations can be deeply merged.

Example:

```yaml
# default.yaml
foo:
  bar: baz
  quux: hello
  
# production.yaml
foo:
  quux: goodbye
  yellow: submarine
  
# Propagates to:
foo:
  bar: baz
  quux: goodbye
  yellow: submarine
```