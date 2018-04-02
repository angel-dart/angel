import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:intl/intl.dart';

final DateFormat _fmt = new DateFormat('EEE, d MMM yyyy HH:mm:ss');

/// Formats a date (converted to UTC), ex: `Sun, 03 May 2015 23:02:37 GMT`.
String _formatDateForHttp(DateTime dt) => _fmt.format(dt.toUtc()) + ' GMT';

class ResponseCache {
  final List<Pattern> patterns = [];
  final Duration timeout;
  final Map<String, _CachedResponse> _cache = {};

  ResponseCache({this.timeout});

  /// A middleware that handles requests with an `If-Modified-Since` header.
  ///
  /// This prevents the server from even having to access the cache, and plays very well with static assets.
  Future<bool> ifModifiedSince(RequestContext req, ResponseContext res) async {
    if (req.headers.value('if-modified-since') != null) {
      var modifiedSince = _fmt.parse(req.headers.value('if-modified-since'));

      // Check if there is a cache entry.
      for (var pattern in patterns) {
        if (pattern.allMatches(req.uri.path).isNotEmpty &&
            _cache.containsKey(req.uri.path)) {
          var response = _cache[req.uri.path];

          // Only send a cached response if it is valid.
          if (timeout == null ||
              modifiedSince.difference(response.timestamp) >= timeout) {
            res.statusCode = 304;
            return false;
          }
        }
      }
    }

    return true;
  }

  Future<bool> responseFinalizer(
      RequestContext req, ResponseContext res) async {
    if (res.statusCode == 304) return true;

    var now = new DateTime.now().toUtc();
  }

  void setCachedHeaders(
      DateTime modified, RequestContext req, ResponseContext res) {
    var privacy = 'public';

    res.headers
      ..['cache-control'] = '$privacy, max-age=${timeout?.inSeconds ?? 0}'
      ..['last-modified'] = _formatDateForHttp(modified);

    if (timeout != null) {
      var expiry = new DateTime.now().add(timeout);
      res.headers['expires'] = _formatDateForHttp(expiry);
    }
  }
}

class _CachedResponse {
  final Map<String, String> headers;
  final List<int> body;
  final DateTime timestamp;

  _CachedResponse({this.headers, this.body, this.timestamp});
}
