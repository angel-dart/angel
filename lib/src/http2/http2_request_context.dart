import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:body_parser/body_parser.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http2/transport.dart';
import 'package:mock_request/mock_request.dart';
import 'package:uuid/uuid.dart';

final RegExp _comma = new RegExp(r',\s*');
final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

class Http2RequestContext extends RequestContext {
  BytesBuilder _buf;
  ContentType _contentType;
  List<Cookie> _cookies;
  HttpHeaders _headers;
  String _method, _override, _path;
  HttpSession _session;
  Socket _socket;
  ServerTransportStream _stream;
  Uri _uri;

  static Future<Http2RequestContext> from(
      ServerTransportStream stream,
      Socket socket,
      Angel app,
      Map<String, MockHttpSession> sessions,
      Uuid uuid) async {
    var req = new Http2RequestContext()
      ..app = app
      .._socket = socket
      .._stream = stream;

    var buf = req._buf = new BytesBuilder();
    var headers = req._headers = new MockHttpHeaders();
    String scheme = 'https',
        authority = '${socket.address.address}:${socket.port}',
        path = '';
    var cookies = <Cookie>[];

    await for (var msg in stream.incomingMessages) {
      if (msg is DataStreamMessage) {
        buf.add(msg.bytes);
      } else if (msg is HeadersStreamMessage) {
        for (var header in msg.headers) {
          var name = ascii.decode(header.name).toLowerCase();
          var value = ascii.decode(header.value);

          switch (name) {
            case ':method':
              req._method = value;
              break;
            case ':path':
              path = value.replaceAll(_straySlashes, '');
              req._path = path;
              if (path.isEmpty) req._path = '/';
              break;
            case ':scheme':
              scheme = value;
              break;
            case ':authority':
              authority = value;
              break;
            case 'cookie':
              var cookieStrings = value.split(';').map((s) => s.trim());

              for (var cookieString in cookieStrings) {
                try {
                  cookies.add(new Cookie.fromSetCookieValue(cookieString));
                } catch (_) {
                  // Ignore malformed cookies, and just don't add them to the container.
                }
              }
              break;
            default:
              headers.add(ascii.decode(header.name), value.split(_comma));
              break;
          }
        }
      }

      //if (msg.endStream) break;
    }

    req
      .._cookies = new List.unmodifiable(cookies)
      .._uri = Uri.parse('$scheme://$authority').replace(path: path);

    // Apply session
    var dartSessId =
        cookies.firstWhere((c) => c.name == 'DARTSESSID', orElse: () => null);

    if (dartSessId == null) {
      dartSessId = new Cookie('DARTSESSID', uuid.v4());
    }

    req._session = sessions.putIfAbsent(
      dartSessId.value,
      () => new MockHttpSession(id: dartSessId.value),
    );

    return req;
  }

  @override
  List<Cookie> get cookies => _cookies;

  /// The underlying HTTP/2 [ServerTransportStream].
  ServerTransportStream get stream => _stream;

  @override
  bool get xhr {
    return headers.value("X-Requested-With")?.trim()?.toLowerCase() ==
        'xmlhttprequest';
  }

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
  ContentType get contentType =>
      _contentType ??= (headers['content-type'] == null
          ? null
          : ContentType.parse(headers.value('content-type')));

  @override
  String get originalMethod {
    return _method;
  }

  @override
  String get method {
    return _override ?? _method;
  }

  @override
  HttpRequest get io => null;

  @override
  String get hostname => _headers.value('host');

  @override
  HttpHeaders get headers => _headers;

  @override
  Future close() {
    return super.close();
  }

  @override
  Future<BodyParseResult> parseOnce() {
    return parseBodyFromStream(
      new Stream.fromIterable([_buf.takeBytes()]),
      contentType == null ? null : new MediaType.parse(contentType.toString()),
      uri,
      storeOriginalBuffer: app.storeOriginalBuffer,
    );
  }
}
