import 'package:angel_framework/angel_framework.dart';
import 'package:user_agent/user_agent.dart';
export 'package:user_agent/user_agent.dart';

/// Injects a [UserAgent] into requests.
///
/// If [strict] is `true`, then requests without a user agent will be rejected.
RequestMiddleware parseUserAgent({bool strict: true}) {
  return (RequestContext req, res) async {
    var agentString = req.headers.value('user-agent');

    if (agentString == null) {
      throw new AngelHttpException.badRequest(
          message: 'User-Agent header is required.');
    } else if (agentString != null) {
      Map<String, List<String>> map = {};
      req.headers.forEach((k, v) => map[k] = v);

      req.inject(UserAgent, new UserAgent(agentString, headers: map));
    }

    return true;
  };
}
