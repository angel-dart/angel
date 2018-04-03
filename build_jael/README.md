# build_jael
[![Pub](https://img.shields.io/pub/v/build_jael.svg)](https://pub.dartlang.org/packages/build_jael)
[![build status](https://travis-ci.org/angel-dart/jael.svg)](https://travis-ci.org/angel-dart/jael)


Compile Jael files to HTML using the power of `package:build`.

# Installation
In your `pubspec.yaml`:

```yaml
dependencies:
  build_jael: ^1.0.0
dev_dependencies:
  build_runner: ^0.7.0
```

# Usage
You can run `pub run build_runner serve` to incrementally build Jael templates,
and run an HTTP server.

For further customization, you'll need to either modify the `build.yaml` or
instantiate a `JaelBuilder` manually.

## Defining Variables
Pass variables as `config` in `build.yaml`:

```yaml
targets:
  $default:
    builders:
      build_jael:
        config:
          foo: bar
          baz: quux
          one: 1.0
```

## Minifying HTML
Pass `minify: true` in the build configuration to produce "minified" HTML,
without newlines or whitespace (other than where it is required).

## Strict Variable Resolution
By default, identifiers pointing to non-existent symbols return `null`.
To disable this and throw an error when an undefined symbol is referenced,
set `strict: true` in `build.yaml`.

To apply additional transforms to parsed documents, provide a
set of `patch` functions, like in `package:jael_preprocessor`.