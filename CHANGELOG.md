# 2.1.0
* Add `loadStandaloneConfiguration`.

# 2.0.0
* Use Angel 2.

# 1.2.0-rc.0
* Removed the `Configuration` class.
* Removed the `ConfigurationTransformer` class.
* Use `Map` casting to prevent runtime cast errors.

# 1.1.0 (Retroactive changelog)
* Use `package:file`.

# 1.0.5
* Now using `package:merge_map` to merge configurations. Resolves
[#5](https://github.com/angel-dart/configuration/issues/5).
* You can now specify a custom `envPath`.