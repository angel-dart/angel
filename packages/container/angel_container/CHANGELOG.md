# 1.1.0
* `pedantic` lints.
* Add `ThrowingReflector`, which throws on all operations.
* `EmptyReflector` uses `Object` instead of `dynamic` as its returned
type, as the `dynamic` type is (apparently?) no longer a valid constant value.
* `registerSingleton` now returns the provided `object`.
* `registerFactory` and `registerLazySingleton` now return the provided function `f`.

# 1.0.4
* Slight patch to prevent annoying segfault.

# 1.0.3
* Added `Future` support to `Reflector`.

# 1.0.2
* Added `makeAsync<T>`.

# 1.0.1
* Added `hasNamed`.

# 1.0.0
* Removed `@GenerateReflector`.

# 1.0.0-alpha.12
* `StaticReflector` now defaults to empty arguments.

# 1.0.0-alpha.11
* Added `StaticReflector`.

# 1.0.0-alpha.10
* Added `Container.registerLazySingleton<T>`.
* Added named singleton support.

# 1.0.0-alpha.9
* Added `Container.has<T>`.

# 1.0.0-alpha.8
* Fixed a bug where `_ReflectedTypeInstance.isAssignableTo` always failed.
* Added `@GenerateReflector` annotation.

# 1.0.0-alpha.7
* Add `EmptyReflector`.
* `ReflectedType.newInstance` now returns a `ReflectedInstance`.
* Moved `ReflectedInstance.invoke` to `ReflectedFunction.invoke`.

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