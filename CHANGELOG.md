# 1.2.0
* `ServiceList` now uses `Equality` from `package:collection` to compare items.
* `Service`s will now add service errors to corresponding streams if there is a listener.

# 1.1.0+3
* `ServiceList` no longer ignores empty `index` events.

# 1.1.0+2
* Updated `ServiceList` to also fire on `index`.

# 1.1.0+1
* Added `ServiceList`.