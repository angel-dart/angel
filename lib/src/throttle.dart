import 'package:angel_framework/angel_framework.dart';

/// Prevents users from sending more than a given [max] number of
/// requests within a given [duration].
///
/// Use [identify] to create a unique identifier for each request.
/// The default is to identify requests by their source IP.
///
/// This works well attached to a `multiserver` instance.
RequestMiddleware throttleRequests(int max, Duration duration,
    {String message: '429 Too Many Requests', identify(RequestContext req)}) {
  var identifyRequest = identify ?? (RequestContext req) async => req.ip;
  Map<String, int> table = {};
  Map<String, List<int>> times = {};

  return (RequestContext req, ResponseContext res) async {
    var id = (await identifyRequest(req)).toString();
    int currentCount;

    var now = new DateTime.now().millisecondsSinceEpoch;
    int firstVisit;

    // If the user has visited within the given duration...
    if (times.containsKey(id)) {
      firstVisit = times[id].first;
    }

    // If difference in times is greater than duration, reset counter ;)
    if (firstVisit != null) {
      if (now - firstVisit > duration.inMilliseconds) {
        table.remove(id);
        times.remove(id);
      }
    }

    // Save to time table
    if (times.containsKey(id))
      times[id].add(now);
    else
      times[id] = [now];

    if (table.containsKey(id))
      currentCount = table[id] = table[id] + 1;
    else
      currentCount = table[id] = 1;

    if (currentCount > max) {
      throw new AngelHttpException(null,
          statusCode: 429, message: message ?? '429 Too Many Requests');
    }

    return true;
  };
}
