# angel_hbs
Handlebars view generator for Angel.

# Installation
In `pubspec.yaml`:

    dependencies:
        angel_mustache: ">= 1.0.0-dev < 2.0.0"

# Usage
```
app.configure(mustache(new Directory('views')));
```

```
res.render('hello', {'name': 'world'});
```