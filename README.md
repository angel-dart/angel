# pretty\_logging
[![Pub](https://img.shields.io/pub/v/pretty_logging.svg)](https://pub.dartlang.org/packages/pretty_logging)

Standalone helper for colorful logging output, using pkg:io AnsiCode.

# Installation
In your `pubspec.yaml`:

```yaml
dependencies:
  pretty_logging: 1.0.0
```

# Usage
Basic usage is very simple:

```dart
myLogger.onRecord.listen(prettyLog);
```

However, you can conditionally pass logic to omit printing an
error, provide colors, or to provide a custom print function:

```dart
var pretty = prettyLog(
  logColorChooser: (_) => red,
  printFunction: stderr.writeln,
  omitError: (r) {
    var err = r.error;
    return err is AngelHttpException && err.statusCode != 500;
  },
);
myLogger.onRecord.listen(pretty);
```
