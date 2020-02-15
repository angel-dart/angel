import 'dart:async';
import 'dart:io';
import 'package:angel_container/angel_container.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:mock_request/mock_request.dart';
import 'package:shelf/shelf.dart' as shelf;

class ShelfRequestContext extends RequestContext {
  @override
  final Angel app;
  @override
  final Container container;
  @override
  final shelf.Request rawRequest;
  @override
  final String path;

  List<Cookie> _cookies;

  @override
  final MockHttpHeaders headers = MockHttpHeaders();

  ShelfRequestContext(this.app, this.container, this.rawRequest, this.path) {
    rawRequest.headers.forEach(headers.add);
  }

  @override
  Stream<List<int>> get body => rawRequest.read();

  @override
  List<Cookie> get cookies {
    if (_cookies == null) {
      // Parse cookies
      _cookies = [];
      var value = headers.value('cookie');
      if (value != null) {
        var cookieStrings = value.split(';').map((s) => s.trim());

        for (var cookieString in cookieStrings) {
          try {
            _cookies.add(Cookie.fromSetCookieValue(cookieString));
          } catch (_) {
            // Ignore malformed cookies, and just don't add them to the container.
          }
        }
      }
    }
    return _cookies;
  }

  @override
  String get hostname => rawRequest.headers['host'];

  @override
  String get method {
    if (!app.allowMethodOverrides) {
      return originalMethod;
    } else {
      return headers.value('x-http-method-override')?.toUpperCase() ??
          originalMethod;
    }
  }

  @override
  String get originalMethod => rawRequest.method;

  @override
  // TODO: implement remoteAddress
  InternetAddress get remoteAddress => null;

  @override
  // TODO: implement session
  HttpSession get session => null;

  @override
  Uri get uri => rawRequest.url;
}
