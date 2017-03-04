/// Easy helper hooks.
library angel_framework.hooks;

import 'dart:async';
import 'dart:mirrors';
import 'package:json_god/json_god.dart' as god;
import 'angel_framework.dart';

/// Sequentially runs a set of [listeners].
HookedServiceEventListener chainListeners(
    Iterable<HookedServiceEventListener> listeners) {
  return (HookedServiceEvent e) async {
    for (HookedServiceEventListener listener in listeners) await listener(e);
  };
}

/// Runs a [callback] on every service, and listens for future services to run it again.
AngelConfigurer hookAllServices(callback(Service service)) {
  return (Angel app) async {
    List<Service> touched = [];

    for (var service in app.services.values) {
      if (!touched.contains(service)) {
        await callback(service);
        touched.add(service);
      }
    }

    app.onService.listen((service) {
      if (!touched.contains(service)) return callback(service);
    });
  };
}

/// Transforms `e.data` or `e.result` into JSON-friendly data, i.e. a Map.
HookedServiceEventListener toJson() {
  return (HookedServiceEvent e) {
    normalize(obj) {
      if (obj != null && obj is! Map) return god.serializeObject(obj);
      return obj;
    }

    if (e.isBefore) {
      return e.data = normalize(e.data);
    } else
      e.result = normalize(e.result);
  };
}

/// Transforms `e.data` or `e.result` into an instance of the given [type],
/// if it is not already.
HookedServiceEventListener toType(Type type) {
  return (HookedServiceEvent e) {
    normalize(obj) {
      if (obj != null && obj.runtimeType != type)
        return god.deserializeDatum(obj, outputType: type);
      return obj;
    }

    if (e.isBefore) {
      return e.data = normalize(e.data);
    } else
      e.result = normalize(e.result);
  };
}

/// Removes one or more [key]s from `e.data` or `e.result`.
/// Works on single objects and iterables.
HookedServiceEventListener remove(key, [remover(key, obj)]) {
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
      else {
        try {
          reflect(obj).setField(new Symbol(key), null);
          return obj;
        } catch (e) {
          throw new ArgumentError("Cannot remove key 'key' from $obj.");
        }
      }
    }

    var keys = key is Iterable ? key : [key];

    _removeAll(obj) async {
      var r = obj;

      for (var key in keys) {
        r = await _remover(key, r);
      }

      return r;
    }

    normalize(obj) async {
      if (obj != null) {
        if (obj is Iterable) {
          var r = await Future.wait(obj.map(_removeAll));
          obj = obj is List ? r.toList() : r;
        } else
          obj = await _removeAll(obj);
      }
    }

    await normalize(e.isBefore ? e.data : e.result);
  };
}

/// Disables a service method for client access from a provider.
///
/// [provider] can be either a String, [Providers], an Iterable of String, or a
/// function that takes a [HookedServiceEvent] and returns a bool.
/// Futures are allowed.
///
/// If [provider] is `null`, then it will be disabled to all clients.
HookedServiceEventListener disable([provider]) {
  return (HookedServiceEvent e) async {
    if (e.params.containsKey('provider')) {
      if (provider == null)
        throw new AngelHttpException.methodNotAllowed();
      else if (provider is Function) {
        var r = await provider(e);
        if (r != true) throw new AngelHttpException.methodNotAllowed();
      } else {
        _provide(p) => p is Providers ? p : new Providers(p.toString());

        var providers = provider is Iterable
            ? provider.map(_provide)
            : [_provide(provider)];

        if (providers.any((Providers p) => p == e.params['provider'])) {
          throw new AngelHttpException.methodNotAllowed();
        }
      }
    }
  };
}
