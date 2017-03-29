/// Browser library for the Angel framework.
library angel_client.browser;

import 'dart:async' show Future, Stream, StreamController, Timer;
import 'dart:convert' show JSON;
import 'dart:html' show CustomEvent, window;
import 'package:http/browser_client.dart' as http;
import 'angel_client.dart';
// import 'auth_types.dart' as auth_types;
import 'base_angel_client.dart';
export 'angel_client.dart';

/// Queries an Angel server via REST.
class Rest extends BaseAngelClient {
  Rest(String basePath) : super(new http.BrowserClient(), basePath);

  @override
  Future<AngelAuthResult> authenticate(
      {String type,
      credentials,
      String authEndpoint: '/auth',
      String reviveEndpoint: '/auth/token'}) async {
    if (type == null) {
      if (!window.localStorage.containsKey('token')) {
        throw new Exception(
            'Cannot revive token from localStorage - there is none.');
      }

      try {
        final result = await super.authenticate(
            type: null,
            credentials: {'token': JSON.decode(window.localStorage['token'])},
            reviveEndpoint: reviveEndpoint);
        window.localStorage['token'] = JSON.encode(authToken = result.token);
        window.localStorage['user'] = JSON.encode(result.data);
        return result;
      } catch (e, st) {
        throw new AngelHttpException(e,
            message: 'Failed to revive auth token.', stackTrace: st);
      }
    } else {
      final result = await super.authenticate(
          type: type, credentials: credentials, authEndpoint: authEndpoint);
      window.localStorage['token'] = JSON.encode(authToken = result.token);
      window.localStorage['user'] = JSON.encode(result.data);
      return result;
    }
  }

  @override
  Stream<String> authenticateViaPopup(String url,
      {String eventName: 'token', String errorMessage}) {
    var ctrl = new StreamController<String>();
    var wnd = window.open(url, 'angel_client_auth_popup');

    Timer t;
    t = new Timer.periodic(new Duration(milliseconds: 500), (timer) {
      if (!ctrl.isClosed) {
        if (wnd.closed) {
          ctrl.addError(new AngelHttpException.notAuthenticated(
              message:
                  errorMessage ?? 'Authentication via popup window failed.'));
          ctrl.close();
          timer.cancel();
        }
      } else
        timer.cancel();
    });

    window.on[eventName ?? 'token'].listen((CustomEvent e) {
      if (!ctrl.isClosed) {
        ctrl.add(e.detail);
        t.cancel();
        ctrl.close();
      }
    });

    return ctrl.stream;
  }

  @override
  Future logout() {
    window.localStorage.remove('token');
    return super.logout();
  }
}
