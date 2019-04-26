import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart-ext:angel_wings';

int bindWingsIPv4ServerSocket(Uint8List address, int port, SendPort sendPort)
    native 'Dart_WingsSocket_bind';

int bindWingsIPv6ServerSocket(Uint8List address, int port, SendPort sendPort)
    native 'Dart_WingsSocket_bind';

int getWingsServerSocketPort(int pointer) native 'Dart_WingsSocket_getPort';

void writeToNativeSocket(int fd, Uint8List data)
    native 'Dart_WingsSocket_write';

void closeNativeSocketDescriptor(int fd)
    native 'Dart_WingsSocket_closeDescriptor';

void closeWingsSocket(int pointer) native 'Dart_WingsSocket_close';

class WingsSocket extends Stream<int> {
  final StreamController<int> _ctrl = StreamController();
  final int _pointer;
  final RawReceivePort _recv;
  bool _open = true;
  int _port;

  WingsSocket._(this._pointer, this._recv) {
    _recv.handler = (h) {
      if (!_ctrl.isClosed) {
        _ctrl.add(h as int);
      }
    };
  }

  static WingsSocket bind(InternetAddress address, int port) {
    var recv = RawReceivePort();
    int ptr;

    try {
      if (address.type == InternetAddressType.IPv6) {
        ptr = bindWingsIPv6ServerSocket(
            Uint8List.fromList(address.rawAddress), port, recv.sendPort);
      } else {
        ptr = bindWingsIPv4ServerSocket(
            Uint8List.fromList(address.rawAddress), port, recv.sendPort);
      }

      return WingsSocket._(ptr, recv);
    } catch (e) {
      recv.close();
      rethrow;
    }
  }

  int get port => _port ??= getWingsServerSocketPort(_pointer);

  @override
  StreamSubscription<int> listen(void Function(int event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    return _ctrl.stream
        .listen(onData, onError: onError, cancelOnError: cancelOnError);
  }

  Future<void> close() async {
    if (_open) {
      _open = false;
      closeWingsSocket(_pointer);
      _recv.close();
      await _ctrl.close();
    }
  }
}
