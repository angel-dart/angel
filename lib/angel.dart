import 'package:angel_framework/angel_framework.dart';
import 'user_agent.dart';

/// Injects a [UserAgent] into requests.
/// 
/// If [strict] is `true`, then an invalid
/// `User-Agent` header will throw a `400 Bad Request`.
RequestMiddleware parseUserAgent({bool strict: true}) {
  return (req, res) async {
    try {
      req.inject(UserAgent, parse(req.headers.value('User-Agent')));
    } catch (e) {
      if (e is UserAgentException && strict) {
        throw new AngelHttpException.BadRequest(message: 'Invalid user agent.');
      } else {
        rethrow;
      }
    }
    
    return true;
  };
}
