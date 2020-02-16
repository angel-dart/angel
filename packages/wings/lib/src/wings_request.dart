import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:angel_container/angel_container.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:mock_request/mock_request.dart';
import 'wings_socket.dart';

enum _ParseState { method, url, headerField, headerValue, body }

final RegExp _straySlashes = RegExp(r'(^/+)|(/+$)');

class WingsRequestContext extends RequestContext<WingsClientSocket> {
  final WingsClientSocket rawRequest;
  final Container container;

  final StreamController<List<int>> _body = StreamController();
  List<Cookie> _cookies, __cookies;
  final LockableMockHttpHeaders _headers = LockableMockHttpHeaders();
  final RawReceivePort _recv;
  InternetAddress _remoteAddress;
  String _method, _override, _path;
  Uri _uri;

  @override
  Angel app;

  WingsRequestContext._(this.app, this.rawRequest, this._recv)
      : container = app.container.createChild();

  Future<void> close() async {
    await _body.close();
    _recv.close();
    await super.close();
  }

  static const int DELETE = 0,
      GET = 1,
      HEAD = 2,
      POST = 3,
      PUT = 4,
      CONNECT = 5,
      OPTIONS = 6,
      TRACE = 7,
      COPY = 8,
      LOCK = 9,
      MKCOL = 10,
      MOVE = 11,
      PROPFIND = 12,
      PROPPATCH = 13,
      SEARCH = 14,
      UNLOCK = 15,
      BIND = 16,
      REBIND = 17,
      UNBIND = 18,
      ACL = 19,
      REPORT = 20,
      MKACTIVITY = 21,
      CHECKOUT = 22,
      MERGE = 23,
      MSEARCH = 24,
      NOTIFY = 25,
      SUBSCRIBE = 26,
      UNSUBSCRIBE = 27,
      PATCH = 28,
      PURGE = 29,
      MKCALENDAR = 30,
      LINK = 31,
      UNLINK = 32,
      SOURCE = 33;

  static String methodToString(int method) {
    switch (method) {
      case DELETE:
        return 'DELETE';
      case GET:
        return 'GET';
      case HEAD:
        return 'HEAD';
      case POST:
        return 'POST';
      case PUT:
        return 'PUT';
      case CONNECT:
        return 'CONNECT';
      case OPTIONS:
        return 'OPTIONS';
      case PATCH:
        return 'PATCH';
      case PURGE:
        return 'PURGE';
      default:
        throw ArgumentError('Unknown method $method.');
    }
  }

  static Future<WingsRequestContext> from(Angel app, WingsClientSocket socket) {
    // var state = _ParseState.url;
    var c = Completer<WingsRequestContext>();
    var recv = RawReceivePort();
    var rq = WingsRequestContext._(app, socket, recv);
    rq._remoteAddress = socket.remoteAddress;
    var ct = StreamController();
    recv.handler = ct.add;
    recv.handler = (ee) {
      if (ee is Uint8List) {
        if (!rq._body.isClosed) rq._body.add(ee);
      } else if (ee is List) {
        var type = ee[0] as int;

        if (type == 2) {
          rq._method = methodToString(ee[1] as int);
        } else {
          var value = ee[1] as String;

          if (type == 0) {
            rq._uri = Uri.parse(value);
            var path = rq._uri.path.replaceAll(_straySlashes, '');
            if (path.isEmpty) path = '/';
            rq._path = path;
          } else if (type == 1) {
            var k = value, v = ee[2] as String;
            if (k == 'cookie') {
              rq.__cookies.add(Cookie.fromSetCookieValue(v));
            } else {
              rq._headers.add(k, v);
            }
          } else {
            // print("h: $ee');");
          }
        }
      } else if (ee == 100) {
        // Headers done, just listen for body.
        c.complete(rq);
      } else if (ee == 200) {
        // Message complete.
        rq._body.close();
      }
      // if (state == _ParseState.url) {
      //   rq._uri = Uri.parse(e as String);
      //   var path = rq._uri.path.replaceAll(_straySlashes, '');
      //   if (path.isEmpty) path = '/';
      //   rq._path = path;
      //   state = _ParseState.headerField;
      // } else if (state == _ParseState.headerField) {
      //   if (e == 0) {
      //     state = _ParseState.method;
      //   } else {
      //     lastHeader = e as String; //Uri.decodeFull(e as String);
      //     state = _ParseState.headerValue;
      //   }
      // } else if (state == _ParseState.headerValue) {
      //   if (e == 0) {
      //     state = _ParseState.method;
      //   } else {
      //     var value = e as String; //Uri.decodeFull(e as String);
      //     if (lastHeader != null) {
      //       if (lastHeader == 'cookie') {
      //         rq.__cookies.add(Cookie.fromSetCookieValue(value));
      //       } else {
      //         rq._headers.add(lastHeader, value);
      //       }
      //       lastHeader = null;
      //     }
      //   }
      //   state = _ParseState.headerField;
      // } else if (state == _ParseState.method) {
      //   rq._method = methodToString(e as int);
      //   state = _ParseState.body;
      //   c.complete(rq);
      // } else if (state == _ParseState.body) {
      //   if (e == 1) {
      //     rq._body.close();
      //   } else {
      //     rq._body.add(e as List<int>);
      //   }
      // }
    };
    wingsParseHttp().send([recv.sendPort, socket.fileDescriptor]);
    return c.future;
  }

  @override
  Stream<List<int>> get body => _body.stream;

  @override
  List<Cookie> get cookies => _cookies ??= List.unmodifiable(__cookies);

  @override
  HttpHeaders get headers => _headers;

  @override
  String get hostname => headers.value('host');

  @override
  String get method => _override ??=
      (headers.value('x-http-method-override')?.toUpperCase() ?? _method);

  @override
  String get originalMethod => _method;

  @override
  String get path => _path;

  @override
  InternetAddress get remoteAddress => _remoteAddress;

  @override
  // TODO: implement session
  HttpSession get session => null;

  @override
  Uri get uri => _uri;
}
