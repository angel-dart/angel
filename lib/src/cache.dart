import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:angel_framework/angel_framework.dart';
import 'package:async/async.dart';
import 'package:file/file.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'virtual_directory.dart';

final DateFormat _fmt = new DateFormat('EEE, d MMM yyyy HH:mm:ss');

/// Formats a date (converted to UTC), ex: `Sun, 03 May 2015 23:02:37 GMT`.
String formatDateForHttp(DateTime dt) => _fmt.format(dt.toUtc()) + ' GMT';

/// Generates a weak ETag from the given buffer.
String weakEtag(List<int> buf) {
  return 'W/${buf.length}' + BASE64URL.encode(buf);
}

/// Returns a string representation of the given [CacheAccessLevel].
String accessLevelToString(CacheAccessLevel accessLevel) {
  switch (accessLevel) {
    case CacheAccessLevel.PRIVATE:
      return 'private';
    case CacheAccessLevel.PUBLIC:
      return 'public';
    default:
      throw new ArgumentError('Unrecognized cache access level: $accessLevel');
  }
}

/// A `VirtualDirectory` that also sets `Cache-Control` headers.
class CachingVirtualDirectory extends VirtualDirectory {
  final Map<String, String> _etags = {};

  /// Either `PUBLIC` or `PRIVATE`.
  final CacheAccessLevel accessLevel;

  /// If `true`, responses will always have `private, max-age=0` as their `Cache-Control` header.
  final bool noCache;

  /// If `true` (default), `Cache-Control` headers will only be set if the application is in production mode.
  final bool onlyInProduction;

  /// If `true` (default), ETags will be computed and sent along with responses.
  final bool useEtags;

  /// The `max-age` for `Cache-Control`.
  ///
  /// Set this to `null` to leave no `Expires` header on responses.
  final int maxAge;

  CachingVirtualDirectory(Angel app, FileSystem fileSystem,
      {this.accessLevel: CacheAccessLevel.PUBLIC,
      Directory source,
      bool debug,
      Iterable<String> indexFileNames,
      this.maxAge: 0,
      this.noCache: false,
      this.onlyInProduction: false,
      this.useEtags: true,
      String publicPath,
      callback(File file, RequestContext req, ResponseContext res)})
      : super(app, fileSystem,
            source: source,
            indexFileNames: indexFileNames ?? ['index.html'],
            publicPath: publicPath ?? '/',
            callback: callback);

  @override
  Future<bool> serveFile(
      File file, FileStat stat, RequestContext req, ResponseContext res) {
    if (onlyInProduction == true && req.app.isProduction != true) {
      return super.serveFile(file, stat, req, res);
    }

    bool shouldNotCache = noCache == true;

    if (!shouldNotCache) {
      shouldNotCache = req.headers.value('cache-control') == 'no-cache' ||
          req.headers.value('pragma') == 'no-cache';
    }

    if (shouldNotCache) {
      res.headers['cache-control'] = 'private, max-age=0, no-cache';
      return super.serveFile(file, stat, req, res);
    } else {
      if (useEtags == true) {
        var etags = req.headers['if-none-match'];

        if (etags?.isNotEmpty == true) {
          bool hasBeenModified = false;

          for (var etag in etags) {
            if (etag == '*')
              hasBeenModified = true;
            else {
              hasBeenModified = _etags.containsKey(file.absolute.path) &&
                  _etags[file.absolute.path] == etag;
            }
          }

          if (hasBeenModified) {
            res.statusCode = 304;
            setCachedHeaders(stat.modified, req, res);
            return new Future.value(false);
          }
        }
      }

      if (req.headers.ifModifiedSince != null) {
        try {
          var ifModifiedSince = req.headers.ifModifiedSince;

          if (ifModifiedSince.compareTo(stat.modified) >= 0) {
            res.statusCode = 304;
            setCachedHeaders(stat.modified, req, res);

            if (_etags.containsKey(file.absolute.path))
              res.headers['ETag'] = _etags[file.absolute.path];

            return new Future.value(false);
          }
        } catch (_) {
          throw new AngelHttpException.badRequest(
              message: 'Invalid date for If-Modified-Since header.');
        }
      }

      return file.readAsBytes().then((buf) {
        var etag = _etags[file.absolute.path] = weakEtag(buf);
        res.statusCode = 200;
        res.headers
          ..['ETag'] = etag
          ..['content-type'] =
              lookupMimeType(file.path) ?? 'application/octet-stream';
        setCachedHeaders(stat.modified, req, res);
        res.add(buf);
        return false;
      });
    }
  }

  void setCachedHeaders(
      DateTime modified, RequestContext req, ResponseContext res) {
    var privacy = accessLevelToString(accessLevel ?? CacheAccessLevel.PUBLIC);

    res.headers
      ..['cache-control'] = '$privacy, max-age=${maxAge ?? 0}'
      ..['last-modified'] = formatDateForHttp(modified);

    if (maxAge != null) {
      var expiry = new DateTime.now().add(new Duration(seconds: maxAge ?? 0));
      res.headers['expires'] = formatDateForHttp(expiry);
    }
  }
}

enum CacheAccessLevel { PUBLIC, PRIVATE }
