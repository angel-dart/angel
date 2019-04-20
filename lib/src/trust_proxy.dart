import 'dart:io';
import 'package:angel_framework/angel_framework.dart';

/// Injects a [ForwardedClient] if the user comes from a
/// trusted proxy.
///
/// [filter] can be:
/// A `String`, `RegExp`, `InternetAddress`, or an `Iterable`.
///
/// String can take the following formats:
/// 1. 1.2.3.4
/// 2. 1.2.3.*, 1.2.*.*, etc.
RequestHandler trustProxy(filter) {
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
      throw ArgumentError('Cannot use $input as a trusted proxy filter.');
  }

  return (RequestContext req, ResponseContext res) async {
    var ip = req.ip;

    bool check() {
      for (var input in filters) {
        if (input is RegExp && input.hasMatch(ip))
          return true;
        else if (input is InternetAddress && input.address == ip)
          return true;
        else if (input is String && input == ip) return true;
      }

      return false;
    }

    if (check()) {
      Map<String, List<String>> headers = {};

      req.headers.forEach((k, v) {
        if (k.trim().toLowerCase().startsWith('x-forwarded')) headers[k] = v;
      });

      req.container
          .registerSingleton<ForwardedClient>(_ForwardedClientImpl(headers));
    }

    return true;
  };
}

/// Presents information about the client forwarded by a trusted
/// reverse proxy.
abstract class ForwardedClient {
  Map<String, List<String>> get headers;

  String get ip => headers['x-forwarded-for']?.join(',');
  String get host => headers['x-forwarded-host']?.join(',');
  String get protocol => headers['x-forwarded-proto']?.join(',');

  int get port {
    var portString = headers['x-forwarded-proto']?.join(',');
    return portString != null ? int.parse(portString) : null;
  }
}

class _ForwardedClientImpl extends ForwardedClient {
  final Map<String, List<String>> _headers;

  _ForwardedClientImpl(this._headers);

  @override
  Map<String, List<String>> get headers =>
      Map<String, List<String>>.unmodifiable(_headers);
}
