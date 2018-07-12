# 2.0.0
* Removed the `Configuration` class.
* Removed the `ConfigurationTransformer` class.
* Use `Map` casting to prevent runtime cast errors.

# 1.0.5
* Now using `package:merge_map` to merge configurations. Resolves
[#5](https://github.com/angel-dart/configuration/issues/5).
* You can now specify a custom `envPath`.