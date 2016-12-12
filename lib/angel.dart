import 'package:angel_framework/angel_framework.dart';
import 'package:user_agent/user_agent.dart' as ua;

/// Injects a [ua.UserAgent] into requests.
/// 
/// If [strict] is `true`, then an invalid
/// `User-Agent` header will throw a `400 Bad Request`.
RequestMiddleware parseUserAgent({bool strict: true}) {
  return (req, res) async {
    try {
      req.inject(ua.UserAgent, ua.parse(req.headers.value('User-Agent')));
    } catch (e) {
      if (e is ua.UserAgentException && strict) {
        throw new AngelHttpException.BadRequest(message: 'Invalid user agent.');
      } else {
        rethrow;
      }
    }
    
    return true;
  };
}
