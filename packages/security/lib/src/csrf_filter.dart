import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'cookie_signer.dart';

class CsrfToken {
  final String value;

  CsrfToken(this.value);
}

class CsrfFilter {
  final CookieSigner cookieSigner;

  CsrfFilter(this.cookieSigner);

  Future<CsrfToken> readCsrfToken(RequestContext req) async {
    
  }
}
