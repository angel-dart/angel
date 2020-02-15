# 1.1.0
* Updates for `package:graphql_parser@1.2.0`.
* Now that variables are `InputValueContext` descendants, handle them the
same way as other values in `coerceArgumentValues`. TLDR - Removed
now-obsolete, variable-specific logic in `coerceArgumentValues`.
* Pass `argumentName`, not `fieldName`, to type validations.

# 1.0.3
* Make field resolution asynchronous.
* Make introspection cycle-safe.
* Thanks @deep-guarav and @micimize!

# 1.0.2
* https://github.com/angel-dart/graphql/pull/32

# 1.0.1
* Fix a bug where `globalVariables` were not being properly passed
to field resolvers.

# 1.0.0
* Finish testing.
* Add `package:pedantic` fixes.

# 1.0.0-rc.0
* Get the Apollo support working with the latest version of `subscriptions-transport-ws`.

# 1.0.0-beta.4
For some reason, Pub was not including `subscriptions_transport_ws.dart`.

# 1.0.0-beta.3
* Introspection on subscription types (if any).

# 1.0.0-beta.2
* Fix bug where field aliases would not be resolved.

# 1.0.0-beta.1
* Add (currently untested) subscription support.

# 1.0.0-beta
* First release.
