/// This should be used with `multiserver` as an entry
/// point for `spawnIsolates`.
library angel.cluster;

import 'dart:async';
import 'common.dart';

main() async {
  runZoned(startServer(clustered: true), onError: onError);
}

