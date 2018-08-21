import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/core.dart';
import 'http_request_context.dart';

class HttpResponseContext extends ResponseContext<HttpResponse> {
  /// The underlying [HttpResponse] under this instance.
  @override
  final HttpResponse rawResponse;
  Angel app;

  LockableBytesBuilder _buffer;

  final HttpRequestContext _correspondingRequest;
  bool _isClosed = false, _streamInitialized = false;

  HttpResponseContext(this.rawResponse, this.app, [this._correspondingRequest]);

  @override
  RequestContext get correspondingRequest {
    return _correspondingRequest;
  }

  @override
  bool get isOpen {
    return !_isClosed;
  }

  @override
  bool get isBuffered => _buffer != null;

  @override
  BytesBuilder get buffer => _buffer;

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    rawResponse.addError(error, stackTrace);
    super.addError(error, stackTrace);
  }

  @override
  void enableBuffer() {
    _buffer = new LockableBytesBuilder();
  }

  bool _openStream() {
    if (!_streamInitialized) {
      // If this is the first stream added to this response,
      // then add headers, status code, etc.
      rawResponse
        ..statusCode = statusCode
        ..cookies.addAll(cookies);
      headers.forEach(rawResponse.headers.set);
      _isClosed = true;
      releaseCorrespondingRequest();
      return _streamInitialized = true;
    }

    return false;
  }

  @override
  void end() {
    _buffer?.lock();
    _isClosed = true;
    super.end();
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    if (_isClosed && isBuffered) throw ResponseContext.closed();
    var firstStream = _openStream();

    Stream<List<int>> output = stream;

    if (encoders.isNotEmpty && correspondingRequest != null) {
      var allowedEncodings = correspondingRequest.headers
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

      if (allowedEncodings != null) {
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
              rawResponse.headers.set('content-encoding', key);
            }

            output = encoders[key].bind(output);
            break;
          }
        }
      }
    }

    return rawResponse.addStream(output);
  }

  @override
  void add(List<int> data) {
    if (_isClosed && isBuffered)
      throw ResponseContext.closed();
    else if (!isBuffered) {
      _openStream();
      rawResponse.add(data);
    } else
      buffer.add(data);
  }

  @override
  Future close() {
    if (!isBuffered) {
      try {
        rawResponse.close();
      } catch (_) {
        // This only seems to occur on `MockHttpRequest`, but
        // this try/catch prevents a crash.
      }
    }

    _isClosed = true;
    super.close();
    return new Future.value();
  }
}
