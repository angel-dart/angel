import 'package:angel_framework/angel_framework.dart';

/// Returns `true` if the event was triggered server-side.
bool isServerSide(HookedServiceEvent e) => !e.params.containsKey('provider');
