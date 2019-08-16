part of 'native.dart';

List _isSqli(String text) native "Angel_Security_IsSqli";

/// Using `libinjection`, determines whether a string contains
/// a SQL injection.
LibInjectionScore sqlInjectionScore(String text) {
  var result = _isSqli(text);
  return LibInjectionScore(result[0] as bool, result[1] as String);
}

/// Uses `libinjection` to filter out possible SQL injections from the
/// query parameters ([RequestContext.queryParameters]).
/// 
/// Note: This is *destructive*, and modifies the query parameter map,
/// instead of returning new data.
bool sqliFilterQuery(RequestContext req, ResponseContext res) {
  var out = <String, dynamic>{};
  req.queryParameters.forEach((k, v) {
    if (v is! String) {
      out[k] = v;
    } else {
      var score = sqlInjectionScore(v as String);
      if (!score.isInjection) {
        out[k] = v;
      }
    }
  });

  req.queryParameters..clear()..addAll(out);
  return true;
}

class LibInjectionScore {
  final bool isInjection;
  final String signature;

  LibInjectionScore(this.isInjection, [this.signature]);
}
