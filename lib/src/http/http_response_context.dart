import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'http_request_context.dart';
import 'request_context.dart';
import 'response_context.dart';
import 'server.dart';

class HttpResponseContextImpl extends ResponseContext {
  /// The underlying [HttpResponse] under this instance.
  @override
  final HttpResponse io;
  Angel app;

  final HttpRequestContextImpl _correspondingRequest;
  bool _isClosed = false, _useStream = false;

  HttpResponseContextImpl(this.io, this.app, [this._correspondingRequest]);

  @override
  RequestContext get correspondingRequest {
    return _correspondingRequest;
  }

  @override
  bool get streaming {
    return _useStream;
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    io.addError(error, stackTrace);
    super.addError(error, stackTrace);
  }

  @override
  bool useStream() {
    if (!_useStream) {
      // If this is the first stream added to this response,
      // then add headers, status code, etc.
      io
        ..statusCode = statusCode
        ..cookies.addAll(cookies);
      headers.forEach(io.headers.set);
      willCloseItself = _useStream = _isClosed = true;
      releaseCorrespondingRequest();
      return true;
    }

    return false;
  }

  @override
  void end() {
    _isClosed = true;
    super.end();
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    if (_isClosed && !_useStream) throw ResponseContext.closed();
    var firstStream = useStream();

    Stream<List<int>> output = stream;

    if (encoders.isNotEmpty && correspondingRequest != null) {
      var allowedEncodings =
      (correspondingRequest.headers[HttpHeaders.ACCEPT_ENCODING] ?? [])
          .map((str) {
        // Ignore quality specifications in accept-encoding
        // ex. gzip;q=0.8
        if (!str.contains(';')) return str;
        return str.split(';')[0];
      });

      for (var encodingName in allowedEncodings) {
        Converter<List<int>, List<int>> encoder;
        String key = encodingName;

        if (encoders.containsKey(encodingName))
          encoder = encoders[encodingName];
        else if (encodingName == '*') {
          encoder = encoders[key = encoders.keys.first];
        }

        if (encoder != null) {
          if (firstStream) {
            io.headers.set(HttpHeaders.CONTENT_ENCODING, key);
          }

          output = encoders[key].bind(output);
          break;
        }
      }
    }

    return io.addStream(output);
  }

  @override
  void add(List<int> data) {
    if (_isClosed && !_useStream)
      throw ResponseContext.closed();
    else if (_useStream)
      io.add(data);
    else
      buffer.add(data);
  }

  @override
  Future close() async {
    if (_useStream) {
      await io.close();
    }

    _isClosed = true;
    await super.close();
    _useStream = false;
  }
}