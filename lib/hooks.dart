/// Easy helper hooks.
library angel_framework.hooks;

import 'dart:async';
import 'package:json_god/json_god.dart' as god;
import 'angel_framework.dart';

/// Transforms `e.data` into JSON-friendly data, i.e. a Map.
HookedServiceEventListener toJson() {
  return (HookedServiceEvent e) {
    if (e.data != null && e.data is! Map) e.data = god.serializeObject(e.data);
  };
}

/// Transforms `e.data` into an instance of the given [type],
/// if it is not already.
HookedServiceEventListener toType(Type type) {
  return (HookedServiceEvent e) {
    if (e.data != null && e.data.runtimeType != type)
      e.data = god.deserializeDatum(e.data, outputType: type);
  };
}

/// Removes one or more [key]s from service results.
/// Works on single results, and iterable results.
HookedServiceEventListener remove(key, remover(key, obj)) {
  return (HookedServiceEvent e) async {
    if (!e.isAfter) throw new StateError("'remove' only works on after hooks.");

    _remover(key, obj) {
      if (remover != null)
        return remover(key, obj);
      else if (obj is List)
        return obj..remove(key);
      else if (obj is Iterable)
        return obj.where((k) => !key);
      else if (obj is Map)
        return obj..remove(key);
      else if (obj is Extensible)
        return obj..properties.remove(key);
      else
        throw new ArgumentError("Cannot remove key 'key' from $obj.");
    }

    var keys = key is Iterable ? key : [key];

    _removeAll(obj) async {
      var r = obj;

      for (var key in keys) {
        r = await _remover(key, r);
      }

      return r;
    }

    if (e.result is Iterable) {
      var r = await Future.wait(e.result.map(_removeAll));
      e.result = e.result is List ? r.toList() : r;
    } else
      e.result = await _removeAll(e.result);
  };
}

/// Disables a service method for access from a provider.
///
/// [provider] can be either a String, [Providers], an Iterable of String, or a
/// function that takes a [HookedServiceEvent] and returns a bool.
/// Futures are allowed.
HookedServiceEventListener disable([provider]) {
  return (HookedServiceEvent e) async {
    if (provider is Function) {
      var r = await provider(e);

      if (r != true) throw new AngelHttpException.methodNotAllowed();
    } else {
      _provide(p) => p is Providers ? p : new Providers(p.toString());

      var providers =
          provider is Iterable ? provider.map(_provide) : [_provide(provider)];

      if (providers.any((Providers p) => p == e.params['provider'])) {
        throw new AngelHttpException.methodNotAllowed();
      }
    }
  };
}
