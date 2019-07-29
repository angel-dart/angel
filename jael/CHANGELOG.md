# 2.0.2
* Fixed handling of `if` in non-strict mode.
* Roll `JaelFormatter` and `jaelfmt`.

# 2.0.1
* Fixed bug where the `textarea` name check would never return `true`.

# 2.0.0+1
* Meta-update for Pub score.

# 2.0.0
* Dart 2 updates.
* Remove usage of `package:dart2_constant`.

# 1.0.6+1
* Ensure `<element>` passes attributes.

# 1.0.6
* Add `index-as` to `for-each`.
* Support registering + rendering custom elements.
* Improve handling of booleans in non-strict mode.

# 1.0.5
* Add support for DSX, a port of JSX to Dart.

# 1.0.4
* Skip HTML comments in free text.

# 1.0.3
* Fix a scanner bug that prevented proper parsing of HTML nodes
followed by free text.
* Don't trim `<textarea>` content.

# 1.0.2
* Use `package:dart2_constant`.
* Upgrade `package:symbol_table`.
* Added `Renderer.errorDocument`.

# 1.0.1
* Reworked the scanner; thereby fixing an extremely pesky bug
that prevented successful parsing of Jael files containing
JavaScript.