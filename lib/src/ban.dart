import 'dart:io';
import 'package:angel_framework/angel_framework.dart';

/// Throws a 403 Forbidden if the user's IP is banned.
///
/// [filter] can be:
/// A `String`, `RegExp`, `InternetAddress`, or an `Iterable`.
///
/// String can take the following formats:
/// 1. 1.2.3.4
/// 2. 1.2.3.*, 1.2.*.*, etc.
RequestHandler banIp(filter,
    {String message =
        'Your IP address is forbidden from accessing this server.'}) {
  var filters = [];
  Iterable inputs = filter is Iterable ? filter : [filter];

  for (var input in inputs) {
    if (input is RegExp || input is InternetAddress)
      filters.add(input);
    else if (input is String) {
      if (!input.contains('*'))
        filters.add(input);
      else {
        filters.add(RegExp(input.replaceAll('*', '[0-9]+')));
      }
    } else
      throw ArgumentError('Cannot use $input as an IP filter.');
  }

  return (RequestContext req, ResponseContext res) async {
    var ip = req.ip;

    bool check() {
      for (var input in filters) {
        if (input is RegExp && input.hasMatch(ip))
          return false;
        else if (input is InternetAddress && input.address == ip)
          return false;
        else if (input is String && input == ip) return false;
      }

      return true;
    }

    if (!check()) throw AngelHttpException.forbidden(message: message);
    return true;
  };
}

/// Throws a 403 Forbidden if the user's Origin header is banned.
///
/// [filter] can be:
/// A `String`, `RegExp`, or an `Iterable`.
///
/// String can take the following formats:
/// 1. example.com
/// 2. *.example.com, a.b.*.d.e.f, etc.
RequestHandler banOrigin(filter,
    {String message = 'You are forbidden from accessing this server.',
    bool allowEmptyOrigin = false}) {
  var filters = [];
  Iterable inputs = filter is Iterable ? filter : [filter];

  for (var input in inputs) {
    if (input is RegExp)
      filters.add(input);
    else if (input is String) {
      if (!input.contains('*'))
        filters.add(input);
      else {
        filters.add(RegExp(input.replaceAll('*', '[^\.]+')));
      }
    } else
      throw ArgumentError('Cannot use $input as an origin filter.');
  }

  return (RequestContext req, ResponseContext res) async {
    var origin = req.headers.value('origin');

    if ((origin == null || origin.isEmpty) && !allowEmptyOrigin)
      throw AngelHttpException.badRequest(
          message: "'Origin' header is required.");

    bool check() {
      for (var input in filters) {
        if (input is RegExp && input.hasMatch(origin))
          return false;
        else if (input is String && input == origin) return false;
      }

      return true;
    }

    if (!check()) throw AngelHttpException.forbidden(message: message);
    return true;
  };
}
