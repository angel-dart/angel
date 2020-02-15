import 'package:angel_framework/angel_framework.dart';
import 'dart:convert';
import 'package:matcher/matcher.dart';
import 'package:test/test.dart';

main() {
  test('named constructors', () {
    expect(
        AngelHttpException.badRequest(), isException(400, '400 Bad Request'));
    expect(AngelHttpException.notAuthenticated(),
        isException(401, '401 Not Authenticated'));
    expect(AngelHttpException.paymentRequired(),
        isException(402, '402 Payment Required'));
    expect(AngelHttpException.forbidden(), isException(403, '403 Forbidden'));
    expect(AngelHttpException.notFound(), isException(404, '404 Not Found'));
    expect(AngelHttpException.methodNotAllowed(),
        isException(405, '405 Method Not Allowed'));
    expect(AngelHttpException.notAcceptable(),
        isException(406, '406 Not Acceptable'));
    expect(AngelHttpException.methodTimeout(), isException(408, '408 Timeout'));
    expect(AngelHttpException.conflict(), isException(409, '409 Conflict'));
    expect(AngelHttpException.notProcessable(),
        isException(422, '422 Not Processable'));
    expect(AngelHttpException.notImplemented(),
        isException(501, '501 Not Implemented'));
    expect(
        AngelHttpException.unavailable(), isException(503, '503 Unavailable'));
  });

  test('fromMap', () {
    expect(AngelHttpException.fromMap({'status_code': -1, 'message': 'ok'}),
        isException(-1, 'ok'));
  });

  test('toMap = toJson', () {
    var exc = AngelHttpException.badRequest();
    expect(exc.toMap(), exc.toJson());
    var json_ = json.encode(exc.toJson());
    var exc2 = AngelHttpException.fromJson(json_);
    expect(exc2.toJson(), exc.toJson());
  });

  test('toString', () {
    expect(
        AngelHttpException(null, statusCode: 420, message: 'Blaze It')
            .toString(),
        '420: Blaze It');
  });
}

Matcher isException(int statusCode, String message) =>
    _IsException(statusCode, message);

class _IsException extends Matcher {
  final int statusCode;
  final String message;

  _IsException(this.statusCode, this.message);

  @override
  Description describe(Description description) =>
      description.add('has status code $statusCode and message "$message"');

  @override
  bool matches(item, Map matchState) {
    return item is AngelHttpException &&
        item.statusCode == statusCode &&
        item.message == message;
  }
}
