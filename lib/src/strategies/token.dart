import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import '../options.dart';
import '../strategy.dart';

class JwtAuthStrategy extends AuthStrategy {

  @override
  Future authenticate(RequestContext req, ResponseContext res,
      [AngelAuthOptions options]) async {

  }

  @override
  Future<bool> canLogout(RequestContext req, ResponseContext res) async => false;
}