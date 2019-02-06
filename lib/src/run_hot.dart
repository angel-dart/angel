import 'dart:async';
import 'dart:isolate';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc_2;
import 'package:stream_channel/src/isolate_channel.dart';
import 'client.dart';

/// Runs the [f] after connecting to a hot reload server. Runs the [f] as-is if no [sendPort] is given.
Future<T> runHot<T>(
    SendPort sendPort, FutureOr<T> Function(HotReloadClient) f) {
  if (sendPort == null) {
    return Future<T>.sync(() => f(null));
  } else {
    var channel = IsolateChannel.connectSend(sendPort);
    var peer = json_rpc_2.Peer.withoutJson(channel);
    var client = HotReloadClient(peer);
    return Future<T>.sync(() => f(client)).whenComplete(client.close);
  }
}
