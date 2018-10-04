# 1.4.0
* `init` can now produce either 1.x or 2.x projects.

# 1.3.4
* Fix another typo.

# 1.3.3
* Fix a small typo in the model generator.

# 1.3.2
* Restore `part` directives in generated models.

# 1.3.1
* Add `deploy nginx` and `deploy systemd`.

# 1.3.0
* Focus on Dart2 from here on out.
* Update `code_builder`.
* More changes...

# 1.1.5
Deprecated several commands, in favor of the `make`
command:
* `controller`
* `plugin`
* `service`
* `test`

The `rename` command will now replace *all* occurrences
of the old project names with the new one in `config/`
YAML files, and also operates on the glob `config/**/*.yaml`.

Changed the call to run `angel start` to run `dart bin/server.dart` instead, after an
`init` command.
