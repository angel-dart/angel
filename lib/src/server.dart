import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';

abstract class OAuth2Server {
  final AngelAuth auth;

  RequestMiddleware verifyAuthToken() {
    return (req, res) async {
      
    };
  }
}