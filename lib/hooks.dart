/// Easy helper hooks.
library angel_framework.hooks;

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
