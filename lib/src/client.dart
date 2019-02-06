import 'dart:async';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc_2;

/// The client side of the Hot Reload RPC.
class HotReloadClient {
  final StreamController<HotReload> _onReload = StreamController();

  /// The underlying transport.
  final json_rpc_2.Peer peer;

  HotReloadClient(this.peer);

  /// Returns whether the underlying [peer] has been closed.
  bool get isClosed => peer.isClosed;

  /// Fires whenever the sources within the current Isolate are about to be reloaded.
  Stream<HotReload> get onReload => _onReload.stream;

  /// Tell the server to establish file watchers at the given [paths],
  /// which may be files, directories, globs, or even `package:` URI's.
  void watchPaths(Iterable<String> paths) {
    // TODO: Watch paths
  }

  /// Notifies the server that an error has been encountered.
  void reportError(Object error, [StackTrace stackTrace]) {
    // TODO: Error reporting
  }

  void close() {
    peer.close();
    _onReload.close();
  }
}

/// A request from the server to reload the current Isolate.
class HotReload {
  final HotReloadClient _client;
  final List<String> modifiedPaths;

  HotReload._(this._client, this.modifiedPaths);

  /// Successfully terminate this attempt at a hot reload.
  void accept() {
    // TODO: accept
  }

  /// Reject the hot reload attempt
  void reject(Object error, [StackTrace stackTrace]) {
    // TODO: reject
  }
}
