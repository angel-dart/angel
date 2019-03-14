import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart-ext:angel_wings';

int bindNativeServerSocket(String addr, int port, SendPort sendPort)
    native 'Dart_NativeSocket_bind';

void writeToNativeSocket(int fd, Uint8List data)
    native 'Dart_NativeSocket_write';

void closeNativeSocket(int fd) native 'Dart_NativeSocket_close';

class NativeSocket extends Stream<int> {
  final StreamController<int> _ctrl = StreamController();
  final int _pointer;
  bool _open = true;

  NativeSocket._(this._pointer);

  @override
  StreamSubscription<int> listen(void Function(int event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    return _ctrl.stream
        .listen(onData, onError: onError, cancelOnError: cancelOnError);
  }
}
