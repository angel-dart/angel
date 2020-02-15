import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';

import '../core/core.dart';
import 'http_request_context.dart';

/// An implementation of [ResponseContext] that abstracts over an [HttpResponse].
class HttpResponseContext extends ResponseContext<HttpResponse> {
  /// The underlying [HttpResponse] under this instance.
  @override
  final HttpResponse rawResponse;
  Angel app;

  LockableBytesBuilder _buffer;

  final HttpRequestContext _correspondingRequest;
  bool _isDetached = false, _isClosed = false, _streamInitialized = false;

  HttpResponseContext(this.rawResponse, this.app, [this._correspondingRequest]);

  @override
  HttpResponse detach() {
    _isDetached = true;
    return rawResponse;
  }

  @override
  RequestContext get correspondingRequest {
    return _correspondingRequest;
  }

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
    rawResponse.addError(error, stackTrace);
    super.addError(error, stackTrace);
  }

  @override
  void useBuffer() {
    _buffer = LockableBytesBuilder();
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
  set contentType(MediaType value) {
    super.contentType = value;
    if (!_streamInitialized) {
      rawResponse.headers.contentType =
          ContentType(value.type, value.subtype, parameters: value.parameters);
    }
  }

  bool _openStream() {
    if (!_streamInitialized) {
      // If this is the first stream added to this response,
      // then add headers, status code, etc.
      rawResponse
        ..statusCode = statusCode
        ..cookies.addAll(cookies);
      headers.forEach(rawResponse.headers.set);

      if (headers.containsKey('content-length')) {
        rawResponse.contentLength = int.tryParse(headers['content-length']) ??
            rawResponse.contentLength;
      }

      rawResponse.headers.contentType = ContentType(
          contentType.type, contentType.subtype,
          charset: contentType.parameters['charset'],
          parameters: contentType.parameters);

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
              rawResponse.headers.set('content-encoding', key);
              break;
            }
          }
        }
      }

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

    return rawResponse.addStream(output);
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

        rawResponse.add(data);
      }
    } else {
      buffer.add(data);
    }
  }

  @override
  Future close() {
    if (!_isDetached) {
      if (!_isClosed) {
        if (!isBuffered) {
          try {
            _openStream();
            rawResponse.close();
          } catch (_) {
            // This only seems to occur on `MockHttpRequest`, but
            // this try/catch prevents a crash.
          }
        } else {
          _buffer.lock();
        }

        _isClosed = true;
      }

      super.close();
    }
    return Future.value();
  }
}
