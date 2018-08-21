# 1.0.0-alpha.6
* Add `getField` to `ReflectedInstance`.

# 1.0.0-alpha.5
* Remove concrete type from `ReflectedTypeParameter`.

# 1.0.0-alpha.4
* Safely handle `void` return types of methods.

# 1.0.0-alpha.3
* Reflecting `void` in `MirrorsReflector` now forwards to `dynamic`.

# 1.0.0-alpha.2
* Added `ReflectedInstance.reflectee`.

# 1.0.0-alpha.1
* Allow omission of the first argument of `Container.make`, to use
a generic type argument instead.
* `singleton` -> `registerSingleton`
* Add `createChild`, and support hierarchical containers.