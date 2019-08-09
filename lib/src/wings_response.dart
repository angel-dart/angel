import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:angel_framework/angel_framework.dart';
import 'package:charcode/ascii.dart';
import 'wings_request.dart';
import 'wings_socket.dart';

class WingsResponseContext extends ResponseContext<int> {
  @override
  final Angel app;

  @override
  final WingsRequestContext correspondingRequest;

  LockableBytesBuilder _buffer;

  @override
  final int rawResponse;

  bool _isDetached = false, _isClosed = false, _streamInitialized = false;

  WingsResponseContext(this.app, this.rawResponse, [this.correspondingRequest]);

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

  bool _openStream() {
    if (!_streamInitialized) {
      // If this is the first stream added to this response,
      // then add headers, status code, etc.
      var outHeaders = <String, String>{};
      var statusLine =
          utf8.encode('HTTP/1.1 $statusCode').followedBy([$cr, $lf]);
      writeToNativeSocket(rawResponse, Uint8List.fromList(statusLine.toList()));

      headers.forEach((k, v) => outHeaders[k] = v);

      if (headers.containsKey('content-length')) {
        var l = int.tryParse(headers['content-length']);
        if (l != null) {
          outHeaders['content-length'] = l.toString();
        }
      }

      if (contentType != null) {
        outHeaders['content-type'] = contentType.toString();
      }

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
              outHeaders['content-encoding'] = key;
              break;
            }
          }
        }
      }

      void _wh(String k, String v) {
        // var vv =Uri.encodeComponent(v);
        var vv = v;
        var headerLine = utf8.encode('$k: $vv').followedBy([$cr, $lf]);
        writeToNativeSocket(
            rawResponse, Uint8List.fromList(headerLine.toList()));
      }

      outHeaders.forEach(_wh);

      for (var c in cookies) {
        _wh('set-cookie', c.toString());
      }

      writeToNativeSocket(rawResponse, Uint8List.fromList([$cr, $lf]));

      //_isClosed = true;
      return _streamInitialized = true;
    }

    return false;
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    if (_isClosed && isBuffered) throw ResponseContext.closed();
    _openStream();

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

    return output.forEach((buf) {
      if (!_isClosed) {
        writeToNativeSocket(
            rawResponse, buf is Uint8List ? buf : Uint8List.fromList(buf));
      }
    });
  }

  @override
  void add(List<int> data) {
    if (_isClosed && isBuffered) {
      throw ResponseContext.closed();
    } else if (!isBuffered) {
      if (!_isClosed) {
        _openStream();

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

        writeToNativeSocket(
            rawResponse, data is Uint8List ? data : Uint8List.fromList(data));
      }
    } else {
      buffer.add(data);
    }
  }

  @override
  Future close() async {
    if (!_isDetached) {
      if (!_isClosed) {
        _isClosed = true;
        if (!isBuffered) {
          _openStream();
          closeNativeSocketDescriptor(rawResponse);
        } else {
          _buffer.lock();
        }
      }

      await correspondingRequest?.close();
      await super.close();
    }
  }

  @override
  BytesBuilder get buffer => _buffer;

  @override
  int detach() {
    _isDetached = true;
    return rawResponse;
  }

  @override
  bool get isBuffered => _buffer != null;

  @override
  bool get isOpen => !_isClosed && !_isDetached;

  @override
  void useBuffer() {
    _buffer = LockableBytesBuilder();
  }
}
