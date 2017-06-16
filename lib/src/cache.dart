import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'file_info.dart';
import 'file_transformer.dart';
import 'virtual_directory.dart';

final DateFormat _fmt = new DateFormat('EEE, d MMM yyyy HH:mm:ss');

/// Formats a date (converted to UTC), ex: `Sun, 03 May 2015 23:02:37 GMT`.
String formatDateForHttp(DateTime dt) => _fmt.format(dt.toUtc()) + ' GMT';

/// Generates an ETag from the given buffer.
String generateEtag(List<int> buf, {bool weak: true, Hash hash}) {
  if (weak == false) {
    Hash h = hash ?? md5;
    return new String.fromCharCodes(h.convert(buf).bytes);
  } else {
    // length + first 50 bytes as base64url
    return 'W/${buf.length}' + BASE64URL.encode(buf.take(50).toList());
  }
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

/// A static server plug-in that also sets `Cache-Control` headers.
class CachingVirtualDirectory extends VirtualDirectory {
  final Map<String, String> _etags = {};

  /// Either `PUBLIC` or `PRIVATE`.
  final CacheAccessLevel accessLevel;

  /// Used to generate strong ETags, if [useWeakEtags] is false.
  ///
  /// Default: `md5`.
  final Hash hash;

  /// If `true`, responses will always have `private, max-age=0` as their `Cache-Control` header.
  final bool noCache;

  /// If `true` (default), `Cache-Control` headers will only be set if the application is in production mode.
  final bool onlyInProduction;

  /// If `true` (default), ETags will be computed and sent along with responses.
  final bool useEtags;

  /// If `false` (default: `true`), ETags will be generated via MD5 hash.
  final bool useWeakEtags;

  /// The `max-age` for `Cache-Control`.
  final int maxAge;

  CachingVirtualDirectory(
      {this.accessLevel: CacheAccessLevel.PUBLIC,
      Directory source,
      bool debug,
      this.hash,
      Iterable<String> indexFileNames,
      this.maxAge: 0,
      this.noCache: false,
      this.onlyInProduction: false,
      this.useEtags: true,
      this.useWeakEtags: true,
      String publicPath,
      StaticFileCallback callback,
      bool streamToIO: false,
      Iterable<FileTransformer> transformers: const []})
      : super(
            source: source,
            debug: debug == true,
            indexFileNames: indexFileNames ?? ['index.html'],
            publicPath: publicPath ?? '/',
            callback: callback,
            streamToIO: streamToIO == true,
            transformers: transformers ?? []);

  @override
  Future<bool> serveFile(
      File file, FileStat stat, RequestContext req, ResponseContext res) {
    if (onlyInProduction == true && req.app.isProduction == true) {
      return super.serveFile(file, stat, req, res);
    }

    if (noCache == true) {
      res.headers[HttpHeaders.CACHE_CONTROL] = 'private, max-age=0, no-cache';
      return super.serveFile(file, stat, req, res);
    } else {
      if (useEtags == true) {
        var etags = req.headers[HttpHeaders.IF_NONE_MATCH];

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
            res.statusCode = HttpStatus.NOT_MODIFIED;
            setCachedHeaders(stat.modified, req, res);
            return new Future.value(false);
          }
        }
      }

      if (req.headers[HttpHeaders.IF_MODIFIED_SINCE] != null) {
        try {
          var ifModifiedSince = req.headers.ifModifiedSince;

          if (ifModifiedSince.compareTo(stat.modified) >= 0) {
            res.statusCode = HttpStatus.NOT_MODIFIED;
            setCachedHeaders(stat.modified, req, res);

            if (_etags.containsKey(file.absolute.path))
              res.headers[HttpHeaders.ETAG] = _etags[file.absolute.path];

            return new Future.value(false);
          }
        } catch (_) {
          throw new AngelHttpException.badRequest(
              message: 'Invalid date for If-Modified-Since header.');
        }
      }

      return file.readAsBytes().then((buf) {
        var etag = _etags[file.absolute.path] =
            generateEtag(buf, weak: useWeakEtags != false, hash: hash);
        res.headers
          ..[HttpHeaders.ETAG] = etag
          ..[HttpHeaders.CONTENT_TYPE] = lookupMimeType(file.path);
        setCachedHeaders(stat.modified, req, res);

        if (useWeakEtags == false) {
          res
            ..statusCode = 200
            ..willCloseItself = false
            ..buffer.add(buf)
            ..end();
          return new Future.value(false);
        }

        return super.serveFile(file, stat, req, res);
      });
    }
  }

  void setCachedHeaders(
      DateTime modified, RequestContext req, ResponseContext res) {
    var privacy = accessLevelToString(accessLevel ?? CacheAccessLevel.PUBLIC);
    var expiry = new DateTime.now().add(new Duration(seconds: maxAge ?? 0));

    res.headers
      ..[HttpHeaders.CACHE_CONTROL] = '$privacy, max-age=${maxAge ?? 0}'
      ..[HttpHeaders.EXPIRES] = formatDateForHttp(expiry)
      ..[HttpHeaders.LAST_MODIFIED] = formatDateForHttp(modified);
  }

  @override
  Future<bool> serveAsset(
      FileInfo fileInfo, RequestContext req, ResponseContext res) {
    if (onlyInProduction == true && req.app.isProduction == true) {
      return super.serveAsset(fileInfo, req, res);
    }

    if (noCache == true) {
      res.headers[HttpHeaders.CACHE_CONTROL] = 'private, max-age=0, no-cache';
      return super.serveAsset(fileInfo, req, res);
    } else {
      if (useEtags == true) {
        var etags = req.headers[HttpHeaders.IF_NONE_MATCH];

        if (etags?.isNotEmpty == true) {
          bool hasBeenModified = false;

          for (var etag in etags) {
            if (etag == '*')
              hasBeenModified = true;
            else {
              hasBeenModified = _etags.containsKey(fileInfo.filename) &&
                  _etags[fileInfo.filename] == etag;
            }
          }

          if (hasBeenModified) {
            res.statusCode = HttpStatus.NOT_MODIFIED;
            setCachedHeaders(fileInfo.lastModified, req, res);
            return new Future.value(false);
          }
        }
      }
    }

    if (req.headers[HttpHeaders.IF_MODIFIED_SINCE] != null) {
      try {
        var ifModifiedSince = req.headers.ifModifiedSince;

        if (ifModifiedSince.compareTo(fileInfo.lastModified) >= 0) {
          res.statusCode = HttpStatus.NOT_MODIFIED;
          setCachedHeaders(fileInfo.lastModified, req, res);

          if (_etags.containsKey(fileInfo.filename))
            res.headers[HttpHeaders.ETAG] = _etags[fileInfo.filename];

          return new Future.value(false);
        }
      } catch (_) {
        throw new AngelHttpException.badRequest(
            message: 'Invalid date for If-Modified-Since header.');
      }
    }

    return super.serveAsset(fileInfo, req, res);
  }
}

enum CacheAccessLevel { PUBLIC, PRIVATE }
