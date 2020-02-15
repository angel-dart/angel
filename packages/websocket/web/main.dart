import 'dart:html';
import 'package:angel_websocket/browser.dart';

/// Dummy app to ensure client works with DDC.
main() {
  var app = new WebSockets(window.location.origin);
  window.alert(app.baseUrl.toString());

  app.connect().catchError((_) {
    window.alert('no websocket');
  });
}
