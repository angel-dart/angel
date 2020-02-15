import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart' hide Header;
import 'package:http2/transport.dart';
import 'http2_request_context.dart';

class Http2ResponseContext extends ResponseContext<ServerTransportStream> {
  final Angel app;
  final ServerTransportStream stream;

  ServerTransportStream get rawResponse => stream;

  LockableBytesBuilder _buffer;

  final Http2RequestContext _req;

  bool _isDetached = false,
      _isClosed = false,
      _streamInitialized = false,
      _isPush = false;

  Uri _targetUri;

  Http2ResponseContext(this.app, this.stream, this._req) {
    _targetUri = _req.uri;
  }

  final List<Http2ResponseContext> _pushes = [];

  /// Returns `true` if an attempt to [push] a resource will succeed.
  ///
  /// See [ServerTransportStream].`push`.
  bool get canPush => stream.canPush;

  /// Returns a [List] of all resources that have [push]ed to the client.
  List<Http2ResponseContext> get pushes => List.unmodifiable(_pushes);

  @override
  ServerTransportStream detach() {
    _isDetached = true;
    return stream;
  }

  @override
  RequestContext get correspondingRequest => _req;

  Uri get targetUri => _targetUri;

  @override
  bool get isOpen {
    return !_isClosed && !_isDetached;
  }

  @override
  bool get isBuffered => _buffer != null;

  @override
  BytesBuilder get buffer => _buffer;

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    super.addError(error, stackTrace);
  }

  @override
  void useBuffer() {
    _buffer = LockableBytesBuilder();
  }

  /// Write headers, status, etc. to the underlying [stream].
  bool _openStream() {
    if (_isPush || _streamInitialized) return false;

    var headers = <Header>[
      Header.ascii(':status', statusCode.toString()),
    ];

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
            this.headers['content-encoding'] = key;
            break;
          }
        }
      }
    }

    // Add all normal headers
    for (var key in this.headers.keys) {
      headers.add(Header.ascii(key.toLowerCase(), this.headers[key]));
    }

    // Persist session ID
    cookies.add(Cookie('DARTSESSID', _req.session.id));

    // Send all cookies
    for (var cookie in cookies) {
      headers.add(Header.ascii('set-cookie', cookie.toString()));
    }

    stream.sendHeaders(headers);
    return _streamInitialized = true;
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

    return output.forEach(this.stream.sendData);
  }

  @override
  void add(List<int> data) {
    if (!isOpen && isBuffered) {
      throw ResponseContext.closed();
    } else if (!isBuffered) {
      _openStream();

      if (!_isClosed) {
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

        stream.sendData(data);
      }
    } else {
      buffer.add(data);
    }
  }

  @override
  Future close() async {
    if (!_isDetached && !_isClosed && !isBuffered) {
      _openStream();
      await stream.outgoingMessages.close();
    }

    _isClosed = true;
    await super.close();
  }

  /// Pushes a resource to the client.
  Http2ResponseContext push(String path,
      {Map<String, String> headers = const {}, String method = 'GET'}) {
    var targetUri = _req.uri.replace(path: path);

    var h = <Header>[
      Header.ascii(':authority', targetUri.authority),
      Header.ascii(':method', method),
      Header.ascii(':path', targetUri.path),
      Header.ascii(':scheme', targetUri.scheme),
    ];

    for (var key in headers.keys) {
      h.add(Header.ascii(key, headers[key]));
    }

    var s = stream.push(h);
    var r = Http2ResponseContext(app, s, _req)
      .._isPush = true
      .._targetUri = targetUri;
    _pushes.add(r);
    return r;
  }
}
