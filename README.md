# mustache
Mustache (Handlebars) view generator for the [Angel](https://github.com/angel-dart/angel)
web server framework.

# Installation
In `pubspec.yaml`:

```yaml
dependencies:
    angel_mustache: ^1.0.0
```

If your project imports [`package:angel_common`](https://github.com/angel-dart/common),
then this is already installed.

# Usage
```dart
// Run the plug-in
await app.configure(mustache(new Directory('views')));

// Render `hello.mustache`
res.render('hello', {'name': 'world'});
```

# Options
- **partialsPath**: A path within the viewsDirectory to search for partials in.
    Default is `./partials`.
- **fileExtension**: The file extension to search for. Default is `.mustache`.
