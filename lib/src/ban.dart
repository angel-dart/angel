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
RequestMiddleware banIp(filter,
    {String message:
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
        filters.add(new RegExp(input.replaceAll('*', '[0-9]+')));
      }
    } else
      throw new ArgumentError('Cannot use $input as an IP filter.');
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

    if (!check()) throw new AngelHttpException.forbidden(message: message);

    return true;
  };
}
