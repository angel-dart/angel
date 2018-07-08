part of angel_wings;

class WingsRequestContext extends RequestContext {
  final AngelWings _wings;
  final int _sockfd;
  bool _closed = false;

  @override
  Angel app;

  WingsRequestContext._(this._wings, this._sockfd, Angel app) : this.app = app;

  static final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

  final Map<String, String> _headers = {};

  String __contentTypeString;
  //String __path;
  String __url;

  Uint8List _addressBytes;
  StreamController<Uint8List> _body;
  ContentType _contentType;
  List<Cookie> _cookies;
  String _headerField, _hostname, _originalMethod, _method, _path;
  HttpHeaders _httpHeaders;
  InternetAddress _remoteAddress;
  HttpSession _session;
  Uri _uri;

  static String _addressToString(Uint8List bytes, bool ipV6)
      native "AddressToString";

  String get _contentTypeString =>
      __contentTypeString ??= _headers['content-type']?.toString();

  void set _headerValue(String value) {
    if (_headerField != null) {
      _headers[_headerField.toLowerCase()] = value;
      _headerField = null;
    }
  }

  @override
  ContentType get contentType => _contentType ??= (_contentTypeString == null
      ? ContentType.binary
      : ContentType.parse(_contentTypeString));

  @override
  List<Cookie> get cookies {
    if (_cookies != null) {
      return _cookies;
    }

    var cookies = <Cookie>[];

    return _cookies = new List<Cookie>.unmodifiable(cookies);
  }

  @override
  HttpHeaders get headers => _httpHeaders ??= new _WingsIncomingHeaders(this);

  @override
  String get hostname => _hostname ??=
      (_headers['host'] ?? '${_wings.address.address}:${_wings.port}');

  @override
  HttpRequest get io => null;

  @override
  String get method =>
      _method ??= (_headers['x-http-method-override'] ?? originalMethod);

  @override
  String get originalMethod => _originalMethod;

  @override
  Future<BodyParseResult> parseOnce() {
    return parseBodyFromStream(
      _body?.stream ?? new Stream<List<int>>.empty(),
      contentType == null ? null : new MediaType.parse(contentType.toString()),
      uri,
      storeOriginalBuffer: app.storeOriginalBuffer,
    );
  }

  @override
  String get path {
    if (_path != null) {
      return _path;
    } else {
      var path = __url?.replaceAll(_straySlashes, '') ?? '';
      if (path.isEmpty) path = '/';
      return _path = path;
    }
  }

  @override
  InternetAddress get remoteAddress => _remoteAddress ??= new InternetAddress(
      _addressToString(_addressBytes, _addressBytes.length > 4));

  @override
  HttpSession get session {
    if (_session != null) return _session;
    var dartSessIdCookie = cookies.firstWhere((c) => c.name == 'DARTSESSID',
        orElse: () => new Cookie('DARTSESSID', _wings._uuid.v4().toString()));
    return _session = _wings._sessions.putIfAbsent(dartSessIdCookie.value,
        () => new MockHttpSession(id: dartSessIdCookie.value));
  }

  @override
  Uri get uri => _uri ??= Uri.parse(__url);

  @override
  bool get xhr =>
      _headers['x-requested-with']?.trim()?.toLowerCase() == 'xmlhttprequest';
}

class _WingsIncomingHeaders extends HttpHeaders {
  final WingsRequestContext request;

  _WingsIncomingHeaders(this.request);

  UnsupportedError _unsupported() =>
      new UnsupportedError('Cannot modify incoming HTTP headers.');

  @override
  List<String> operator [](String name) {
    return value(name)?.split(',')?.map((s) => s.trim())?.toList();
  }

  @override
  void add(String name, Object value) => throw _unsupported();

  @override
  void clear() => throw _unsupported();

  @override
  void forEach(void Function(String name, List<String> values) f) {
    request._headers.forEach((name, value) =>
        f(name, value.split(',').map((s) => s.trim()).toList()));
  }

  @override
  void noFolding(String name) => throw _unsupported();

  @override
  void remove(String name, Object value) => throw _unsupported();

  @override
  void removeAll(String name) => throw _unsupported();

  @override
  void set(String name, Object value) => throw _unsupported();

  @override
  String value(String name) => request._headers[name.toLowerCase()];
}
