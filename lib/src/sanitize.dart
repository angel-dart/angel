import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';

final Map<Pattern, String> DEFAULT_SANITIZERS = {
  new RegExp(
      r'<\s*s\s*c\s*r\s*i\s*p\s*t\s*>.*<\s*\/\s*s\s*c\s*r\s*i\s*p\s*t\s*>',
      caseSensitive: false): ''
};

/// Mitigates XSS risk by sanitizing user HTML input.
///
/// You can also provide a Map of patterns to [replace].
/// 
/// You can sanitize the [body] or [query] (both `true` by default).
RequestMiddleware sanitizeHtmlInput(
    {bool body: true,
    bool query: true,
    Map<Pattern, String> replace: const {}}) {
  var sanitizers = {}..addAll(DEFAULT_SANITIZERS)..addAll(replace ?? {});

  return (RequestContext req, res) async {
    if (body) _sanitizeMap(await req.lazyBody(), sanitizers);
    if (query) _sanitizeMap(await req.lazyQuery(), sanitizers);
    return true;
  };
}

_sanitize(v, Map<Pattern, String> sanitizers) {
  if (v is String) {
    var str = v;

    sanitizers.forEach((needle, replace) {
      str = str.replaceAll(needle, replace);
    });

    return HTML_ESCAPE.convert(str);
  } else if (v is Map) {
    _sanitizeMap(v, sanitizers);
    return v;
  } else if (v is Iterable) {
    bool isList = v is List;
    var mapped = v.map((x) => _sanitize(x, sanitizers));
    return isList ? mapped.toList() : mapped;
  } else
    return v;
}

void _sanitizeMap(Map data, Map<Pattern, String> sanitizers) {
  data.forEach((k, v) {
    data[k] = _sanitize(v, sanitizers);
  });
}
