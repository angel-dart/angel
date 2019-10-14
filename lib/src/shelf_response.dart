import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'shelf_request.dart';

class ShelfResponseContext extends ResponseContext<ShelfResponseContext> {
  final Angel app;
  final StreamController<List<int>> _ctrl = StreamController();
  bool _isOpen = true,
      _isDetached = false,
      _wasClosedByHandler = false,
      _handlersAreDone = false;

  ShelfResponseContext(this.app);

  ShelfRequestContext _correspondingRequest;

  bool get wasClosedByHandler => _wasClosedByHandler;

  void closeSilently() => _handlersAreDone = true;

  ShelfRequestContext get correspondingRequest => _correspondingRequest;

  set correspondingRequest(ShelfRequestContext value) {
    if (_correspondingRequest == null) {
      _correspondingRequest = value;
    } else {
      throw StateError('The corresponding request has already been assigned.');
    }
  }

  shelf.Response get shelfResponse {
    return shelf.Response(statusCode, body: _ctrl.stream, headers: headers);
  }

  @override
  Future<void> close() {
    if (!_handlersAreDone) {
      _isOpen = false;
    }
    _ctrl.close();
    return super.close();
  }

  Iterable<String> __allowedEncodings;

  Iterable<String> get _allowedEncodings {
    return __allowedEncodings ??= correspondingRequest.headers
        .value('accept-encoding')
        ?.split(',')
        ?.map((s) => s.trim())
        ?.where((s) => s.isNotEmpty)
        ?.map((str) {
      // Ignore quality specifications in accept-encoding
      // ex. gzip;q=0.8
      if (!str.contains(';')) return str;
      return str.split(';')[0];
    });
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    if (!isOpen && isBuffered) throw ResponseContext.closed();
    Stream<List<int>> output = stream;

    if (encoders.isNotEmpty && correspondingRequest != null) {
      if (_allowedEncodings != null) {
        for (var encodingName in _allowedEncodings) {
          Converter<List<int>, List<int>> encoder;
          String key = encodingName;

          if (encoders.containsKey(encodingName)) {
            encoder = encoders[encodingName];
          } else if (encodingName == '*') {
            encoder = encoders[key = encoders.keys.first];
          }

          if (encoder != null) {
            output = encoders[key].bind(output);
            break;
          }
        }
      }
    }

    return _ctrl.addStream(output);
  }

  @override
  void add(List<int> data) {
    if (!isOpen && isBuffered) {
      throw ResponseContext.closed();
    } else if (_isOpen) {
      if (encoders.isNotEmpty && correspondingRequest != null) {
        if (_allowedEncodings != null) {
          for (var encodingName in _allowedEncodings) {
            Converter<List<int>, List<int>> encoder;
            String key = encodingName;

            if (encoders.containsKey(encodingName)) {
              encoder = encoders[encodingName];
            } else if (encodingName == '*') {
              encoder = encoders[key = encoders.keys.first];
            }

            if (encoder != null) {
              data = encoders[key].convert(data);
              break;
            }
          }
        }
      }

      _ctrl.add(data);
    }
  }

  @override
  BytesBuilder get buffer => null;

  @override
  FutureOr<ShelfResponseContext> detach() {
    _isDetached = true;
    return this;
  }

  @override
  bool get isBuffered => false;

  @override
  bool get isOpen => _isOpen && !_isDetached;

  @override
  void useBuffer() {}

  @override
  ShelfResponseContext get rawResponse => this;
}
