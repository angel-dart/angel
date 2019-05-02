import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_container/src/container.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:http2/transport.dart';
import 'package:mock_request/mock_request.dart';
import 'package:uuid/uuid.dart';

final RegExp _comma = RegExp(r',\s*');
final RegExp _straySlashes = RegExp(r'(^/+)|(/+$)');

class Http2RequestContext extends RequestContext<ServerTransportStream> {
  final StreamController<List<int>> _body = StreamController();
  final Container container;
  List<Cookie> _cookies;
  HttpHeaders _headers;
  String _method, _override, _path;
  HttpSession _session;
  Socket _socket;
  ServerTransportStream _stream;
  Uri _uri;

  Http2RequestContext._(this.container);

  @override
  Stream<List<int>> get body => _body.stream;

  static Future<Http2RequestContext> from(
      ServerTransportStream stream,
      Socket socket,
      Angel app,
      Map<String, MockHttpSession> sessions,
      Uuid uuid) {
    var c = Completer<Http2RequestContext>();
    var req = Http2RequestContext._(app.container.createChild())
      ..app = app
      .._socket = socket
      .._stream = stream;

    var headers = req._headers = MockHttpHeaders();
    // String scheme = 'https', host = socket.address.address, path = '';
    var uri =
        Uri(scheme: 'https', host: socket.address.address, port: socket.port);
    var cookies = <Cookie>[];

    void finalize() {
      req
        .._cookies = List.unmodifiable(cookies)
        .._uri = uri;
      if (!c.isCompleted) c.complete(req);
    }

    void parseHost(String value) {
      var inUri = Uri.tryParse(value);
      if (inUri == null) return;
      // if (uri == null || uri.scheme == 'localhost') return;

      if (inUri.hasScheme) uri = uri.replace(scheme: inUri.scheme);

      if (inUri.hasAuthority) {
        uri = uri.replace(host: inUri.host, userInfo: inUri.userInfo);
      }

      if (inUri.hasPort) uri = uri.replace(port: inUri.port);
    }

    stream.incomingMessages.listen((msg) {
      if (msg is DataStreamMessage) {
        finalize();
        req._body.add(msg.bytes);
      } else if (msg is HeadersStreamMessage) {
        for (var header in msg.headers) {
          var name = ascii.decode(header.name).toLowerCase();
          var value = Uri.decodeComponent(ascii.decode(header.value));

          switch (name) {
            case ':method':
              req._method = value;
              break;
            case ':path':
              var inUri = Uri.parse(value);
              uri = uri.replace(path: inUri.path);
              if (inUri.hasQuery) uri = uri.replace(query: inUri.query);
              var path = uri.path.replaceAll(_straySlashes, '');
              req._path = path;
              if (path.isEmpty) req._path = '/';
              break;
            case ':scheme':
              uri = uri.replace(scheme: value);
              break;
            case ':authority':
              parseHost(value);
              break;
            case 'cookie':
              var cookieStrings = value.split(';').map((s) => s.trim());

              for (var cookieString in cookieStrings) {
                try {
                  cookies.add(Cookie.fromSetCookieValue(cookieString));
                } catch (_) {
                  // Ignore malformed cookies, and just don't add them to the container.
                }
              }
              break;
            default:
              var name = ascii.decode(header.name).toLowerCase();

              if (name == 'host') {
                parseHost(value);
              }

              headers.add(name, value.split(_comma));
              break;
          }
        }

        if (msg.endStream) finalize();
      }
    }, onDone: () {
      finalize();
      req._body.close();
    }, cancelOnError: true, onError: c.completeError);

    // Apply session
    var dartSessId =
        cookies.firstWhere((c) => c.name == 'DARTSESSID', orElse: () => null);

    if (dartSessId == null) {
      dartSessId = Cookie('DARTSESSID', uuid.v4());
    }

    req._session = sessions.putIfAbsent(
      dartSessId.value,
      () => MockHttpSession(id: dartSessId.value),
    );

    return c.future;
  }

  @override
  List<Cookie> get cookies => _cookies;

  /// The underlying HTTP/2 [ServerTransportStream].
  ServerTransportStream get stream => _stream;

  @override
  Uri get uri => _uri;

  @override
  HttpSession get session {
    return _session;
  }

  @override
  InternetAddress get remoteAddress => _socket.remoteAddress;

  @override
  String get path {
    return _path;
  }

  @override
  String get originalMethod {
    return _method;
  }

  @override
  String get method {
    return _override ?? _method;
  }

  @override
  String get hostname => _headers.value('host');

  @override
  HttpHeaders get headers => _headers;

  @override
  Future close() {
    _body.close();
    return super.close();
  }

  @override
  ServerTransportStream get rawRequest => _stream;
}
