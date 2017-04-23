import 'package:angel_framework/angel_framework.dart';

/// Prevents a WebSocket event from being broadcasted, to any client from the given [provider].
///
/// [provider] can be a String, a [Provider], or an Iterable.
/// If [provider] is `null`, any provider will be blocked.
HookedServiceEventListener doNotBroadcast([provider]) {
  return (HookedServiceEvent e) {
    if (e.params != null && e.params.containsKey('provider')) {
      bool deny = false;
      Iterable providers = provider is Iterable ? provider : [provider];

      for (var p in providers) {
        if (deny) break;

        if (p is Providers) {
          deny = deny ||
              p == e.params['provider'] ||
              e.params['provider'] == p.via;
        } else if (p == null) {
          deny = true;
        } else
          deny =
              deny || (e.params['provider'] as Providers).via == p.toString();
      }

      e.params['broadcast'] = false;
    }
  };
}
