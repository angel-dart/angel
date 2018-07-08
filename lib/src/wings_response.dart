part of angel_wings;

class WingsResponseContext extends ResponseContext {
  final WingsRequestContext correspondingRequest;
  bool _isClosed = false, _useStream = false;

  WingsResponseContext._(this.correspondingRequest);

  AngelWings get _wings => correspondingRequest._wings;

  @override
  void add(List<int> data) {
    if (_isClosed && !_useStream)
      throw ResponseContext.closed();
    else if (_useStream)
      _wings._send(correspondingRequest._sockfd, _coerceUint8List(data));
    else
      buffer.add(data);
  }

  @override
  Future close() {
    _wings._closeSocket(correspondingRequest);
    _isClosed = true;
    _useStream = false;
    return super.close();
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

    if ((firstStream || !headers.containsKey('content-encoding')) &&
        encoders.isNotEmpty &&
        correspondingRequest != null) {
      var allowedEncodings =
          (correspondingRequest.headers['accept-encoding'] ?? []).map((str) {
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
          /*
          if (firstStream) {
            this.stream.sendHeaders([
              new Header.ascii(
                  'content-encoding', headers['content-encoding'] = key)
            ]);
          }
          */

          output = encoders[key].bind(output);
          break;
        }
      }
    }

    return output.forEach(((data) =>
        _wings._send(correspondingRequest._sockfd, _coerceUint8List(data))));
  }

  @override
  HttpResponse get io => null;

  @override
  bool get isOpen => !_isClosed;

  @override
  bool get streaming => _useStream;

  @override
  bool useStream() {
    if (!_useStream) {
      // If this is the first stream added to this response,
      // then add headers, status code, etc.
      _finalize();

      willCloseItself = _useStream = _isClosed = true;
      releaseCorrespondingRequest();
      return true;
    }

    return false;
  }

  /// Write headers, status, etc. to the underlying [stream].
  void _finalize() {
    var b = new StringBuffer();
    b.writeln('HTTP/1.1 $statusCode');
    headers['date'] ??= HttpDate.format(new DateTime.now());

    if (encoders.isNotEmpty && correspondingRequest != null) {
      var allowedEncodings =
          (correspondingRequest.headers['accept-encoding'] ?? []).map((str) {
        // Ignore quality specifications in accept-encoding
        // ex. gzip;q=0.8
        if (!str.contains(';')) return str;
        return str.split(';')[0];
      });

      for (var encodingName in allowedEncodings) {
        String key = encodingName;

        if (encoders.containsKey(encodingName)) {
          this.headers['content-encoding'] = key;
          break;
        }
      }
    }

    // Add all normal headers
    this.headers.forEach((k, v) {
      b.writeln('$k: $v');
    });

    // Persist session ID
    if (correspondingRequest._session != null) {
      cookies.add(new Cookie('DARTSESSID', correspondingRequest._session.id));
    }

    // Send all cookies
    for (var cookie in cookies) {
      var value = cookie.toString();
      b.writeln('set-cookie: $value');
    }

    b.writeln();

    _wings._send(
        correspondingRequest._sockfd, _coerceUint8List(b.toString().codeUnits));
  }
}

Uint8List _coerceUint8List(List<int> list) =>
    list is Uint8List ? list : new Uint8List.fromList(list);
