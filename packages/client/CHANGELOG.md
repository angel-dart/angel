# 2.0.2
* `_join` previously discarded quer parameters, etc.
* Allow any `Map<String, dynamic>` as body, not just `Map<String, String>`.

# 2.0.1
* Change `BaseAngelClient` constructor to accept `dynamic` instead of `String` for `baseUrl.

# 2.0.0
* Deprecate `basePath` in favor of `baseUrl`.
* `Angel` now extends `http.Client`.
* Deprecate `auth_types`.

# 2.0.0-alpha.2
* Make Service `index` always return `List<Data>`.
* Add `Service.map`.

# 2.0.0-alpha.1
* Refactor `params` to `Map<String, dynamic>`.

# 2.0.0-alpha
* Depend on Dart 2.
* Depend on Angel 2.
* Remove `dart2_constant`.

# 1.2.0+2
* Code cleanup + housekeeping, update to `dart2_constant`, and
ensured build works with `2.0.0-dev.64.1`.

# 1.2.0+1
* Removed a type annotation in `authenticateViaPopup` to prevent breaking with DDC.

# 1.2.0
* `ServiceList` now uses `Equality` from `package:collection` to compare items.
* `Service`s will now add service errors to corresponding streams if there is a listener.

# 1.1.0+3
* `ServiceList` no longer ignores empty `index` events.

# 1.1.0+2
* Updated `ServiceList` to also fire on `index`.

# 1.1.0+1
* Added `ServiceList`.