/// This should be used with `multiserver` as an entry
/// point for `spawnIsolates`.
library angel.cluster;

import 'dart:async';
import 'common.dart';
import 'dart:isolate';

main(args, SendPort sendPort) async {
  runZoned(startServer(args, clustered: true, sendPort: sendPort),
      onError: onError);
}
