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

  final HttpRequestContext _correspondingRequest;
  bool _isClosed = false, _useStream = false;

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
  bool get streaming {
    return _useStream;
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    rawResponse.addError(error, stackTrace);
    super.addError(error, stackTrace);
  }

  @override
  bool useStream() {
    if (!_useStream) {
      // If this is the first stream added to this response,
      // then add headers, status code, etc.
      rawResponse
        ..statusCode = statusCode
        ..cookies.addAll(cookies);
      headers.forEach(rawResponse.headers.set);
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
    if (_isClosed && !_useStream)
      throw ResponseContext.closed();
    else if (_useStream)
      rawResponse.add(data);
    else
      buffer.add(data);
  }

  @override
  Future close() {
    if (_useStream) {
      try {
        rawResponse.close();
      } catch (_) {
        // This only seems to occur on `MockHttpRequest`, but
        // this try/catch prevents a crash.
      }
    }

    _isClosed = true;
    super.close();
    _useStream = false;
    return new Future.value();
  }
}
