import 'package:angel_framework/angel_framework.dart';

/// Prevents a WebSocket event from being broadcasted, to any client.
HookedServiceEventListener doNotBroadcast() {
  return (HookedServiceEvent e) {
    if (e.params != null) e.params['broadcast'] = false;
  };
}
