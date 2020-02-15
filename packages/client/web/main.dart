import 'dart:html';
import 'package:angel_client/browser.dart';

/// Dummy app to ensure client works with DDC.
main() {
  var app = new Rest(window.location.origin);
  window.alert(app.baseUrl.toString());
}
