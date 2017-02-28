/// Browser library for the Angel framework.
library angel_client.browser;

import 'dart:async' show Future, Stream, StreamController;
import 'dart:convert' show JSON;
import 'dart:html' show CustomEvent, window;
import 'package:http/browser_client.dart' as http;
import 'angel_client.dart';
import 'auth_types.dart' as auth_types;
import 'base_angel_client.dart';
export 'angel_client.dart';

/// Queries an Angel server via REST.
class Rest extends BaseAngelClient {
  Rest(String basePath) : super(new http.BrowserClient(), basePath);

  @override
  Future<AngelAuthResult> authenticate(
      {String type: auth_types.LOCAL,
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

    wnd
      ..on['beforeunload'].listen((_) {
        if (!ctrl.isClosed) {
          ctrl.addError(new AngelHttpException.notAuthenticated(
              message:
                  errorMessage ?? 'Authentication via popup window failed.'));
          ctrl.close();
        }
      })
      ..on[eventName ?? 'token'].listen((CustomEvent e) {
        if (!ctrl.isClosed) {
          ctrl.add(e.detail);
          ctrl.close();
        }
      });

    return ctrl.stream;
  }
}
