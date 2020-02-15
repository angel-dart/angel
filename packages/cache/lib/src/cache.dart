import 'dart:async';
import 'dart:io' show HttpDate;
import 'package:angel_framework/angel_framework.dart';
import 'package:pool/pool.dart';

/// A flexible response cache for Angel.
///
/// Use this to improve real and perceived response of Web applications,
/// as well as to memoize expensive responses.
class ResponseCache {
  /// A set of [Patterns] for which responses will be cached.
  ///
  /// For example, you can pass a `Glob` matching `**/*.png` files to catch all PNG images.
  final List<Pattern> patterns = [];

  /// An optional timeout, after which a given response will be removed from the cache, and the contents refreshed.
  final Duration timeout;

  final Map<String, _CachedResponse> _cache = {};
  final Map<String, Pool> _writeLocks = {};

  /// If `true` (default: `false`), then caching of results will discard URI query parameters and fragments.
  final bool ignoreQueryAndFragment;

  ResponseCache({this.timeout, this.ignoreQueryAndFragment: false});

  /// Closes all internal write-locks, and closes the cache.
  Future close() async {
    _writeLocks.forEach((_, p) => p.close());
  }

  /// Removes an entry from the response cache.
  void purge(String path) => _cache.remove(path);

  /// A middleware that handles requests with an `If-Modified-Since` header.
  ///
  /// This prevents the server from even having to access the cache, and plays very well with static assets.
  Future<bool> ifModifiedSince(RequestContext req, ResponseContext res) async {
    if (req.method != 'GET' && req.method != 'HEAD') return true;

    if (req.headers.ifModifiedSince != null) {
      var modifiedSince = req.headers.ifModifiedSince;

      // Check if there is a cache entry.
      for (var pattern in patterns) {
        if (pattern.allMatches(_getEffectivePath(req)).isNotEmpty &&
            _cache.containsKey(_getEffectivePath(req))) {
          var response = _cache[_getEffectivePath(req)];
          //print('timestamp ${response.timestamp} vs since ${modifiedSince}');

          if (response.timestamp.compareTo(modifiedSince) <= 0) {
            if (timeout != null) {
              // If the cache timeout has been met, don't send the cached response.
              if (new DateTime.now().toUtc().difference(response.timestamp) >=
                  timeout) return true;
            }

            res.statusCode = 304;
            return false;
          }
        }
      }
    }

    return true;
  }

  String _getEffectivePath(RequestContext req) =>
      ignoreQueryAndFragment == true ? req.uri.path : req.uri.toString();

  /// Serves content from the cache, if applicable.
  Future<bool> handleRequest(RequestContext req, ResponseContext res) async {
    if (!await ifModifiedSince(req, res)) return false;
    if (req.method != 'GET' && req.method != 'HEAD') return true;
    if (!res.isOpen) return true;

    // Check if there is a cache entry.
    //
    // If `if-modified-since` is present, this check has already been performed.
    if (req.headers.ifModifiedSince == null) {
      for (var pattern in patterns) {
        if (pattern.allMatches(_getEffectivePath(req)).isNotEmpty) {
          var now = new DateTime.now().toUtc();

          if (_cache.containsKey(_getEffectivePath(req))) {
            var response = _cache[_getEffectivePath(req)];

            if (timeout != null) {
              // If the cache timeout has been met, don't send the cached response.
              if (now.difference(response.timestamp) >= timeout) return true;
            }

            _setCachedHeaders(response.timestamp, req, res);
            res
              ..headers.addAll(response.headers)
              ..add(response.body)
              ..close();
            return false;
          } else {
            _setCachedHeaders(now, req, res);
          }
        }
      }
    }

    return true;
  }

  /// A response finalizer that saves responses to the cache.
  Future<bool> responseFinalizer(
      RequestContext req, ResponseContext res) async {
    if (res.statusCode == 304) return true;
    if (req.method != 'GET' && req.method != 'HEAD') return true;

    // Check if there is a cache entry.
    for (var pattern in patterns) {
      if (pattern.allMatches(_getEffectivePath(req)).isNotEmpty) {
        var now = new DateTime.now().toUtc();

        // Invalidate the response, if need be.
        if (_cache.containsKey(_getEffectivePath(req))) {
          // If there is no timeout, don't invalidate.
          if (timeout == null) return true;

          // Otherwise, don't invalidate unless the timeout has been exceeded.
          var response = _cache[_getEffectivePath(req)];
          if (now.difference(response.timestamp) < timeout) return true;

          // If the cache entry should be invalidated, then invalidate it.
          purge(_getEffectivePath(req));
        }

        // Save the response.
        var writeLock =
            _writeLocks.putIfAbsent(_getEffectivePath(req), () => new Pool(1));
        await writeLock.withResource(() {
          _cache[_getEffectivePath(req)] = new _CachedResponse(
              new Map.from(res.headers), res.buffer.toBytes(), now);
        });

        _setCachedHeaders(now, req, res);
      }
    }

    return true;
  }

  void _setCachedHeaders(
      DateTime modified, RequestContext req, ResponseContext res) {
    var privacy = 'public';

    res.headers
      ..['cache-control'] = '$privacy, max-age=${timeout?.inSeconds ?? 86400}'
      ..['last-modified'] = HttpDate.format(modified);

    if (timeout != null) {
      var expiry = new DateTime.now().add(timeout);
      res.headers['expires'] = HttpDate.format(expiry);
    }
  }
}

class _CachedResponse {
  final Map<String, String> headers;
  final List<int> body;
  final DateTime timestamp;

  _CachedResponse(this.headers, this.body, this.timestamp);
}
