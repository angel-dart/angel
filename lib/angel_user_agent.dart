import 'package:angel_framework/angel_framework.dart';
import 'package:ua_parser/ua_parser.dart' as ua;

/// Injects a [ua.Client] and [ua.UserAgent] into requests.
/// 
/// If [strict] is `true`, then an invalid
/// `User-Agent` header will throw a `400 Bad Request`.
RequestMiddleware parseUserAgent({bool strict: true}) {
  return (req, res) async {
    try {
      final client = ua.parse(req.headers.value('User-Agent'));
      req
        ..inject(ua.Client, client)
        ..inject(ua.UserAgent, client.userAgent);
    } catch (e) {
      throw strict ?
        new AngelHttpException.BadRequest(message: 'Invalid user agent.') : e;
    }
    
    return true;
  };
}
