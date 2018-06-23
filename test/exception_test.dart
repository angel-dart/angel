import 'package:angel_framework/angel_framework.dart';
import 'package:dart2_constant/convert.dart';
import 'package:matcher/matcher.dart';
import 'package:test/test.dart';

main() {
  test('named constructors', () {
    expect(new AngelHttpException.badRequest(),
        isException(400, '400 Bad Request'));
    expect(new AngelHttpException.notAuthenticated(),
        isException(401, '401 Not Authenticated'));
    expect(new AngelHttpException.paymentRequired(),
        isException(402, '402 Payment Required'));
    expect(new AngelHttpException.forbidden(),
        isException(403, '403 Forbidden'));
    expect(new AngelHttpException.notFound(),
        isException(404, '404 Not Found'));
    expect(new AngelHttpException.methodNotAllowed(),
        isException(405, '405 Method Not Allowed'));
    expect(new AngelHttpException.notAcceptable(),
        isException(406, '406 Not Acceptable'));
    expect(new AngelHttpException.methodTimeout(),
        isException(408, '408 Timeout'));
    expect(new AngelHttpException.conflict(),
        isException(409, '409 Conflict'));
    expect(new AngelHttpException.notProcessable(),
        isException(422, '422 Not Processable'));
    expect(new AngelHttpException.notImplemented(),
        isException(501, '501 Not Implemented'));
    expect(new AngelHttpException.unavailable(),
        isException(503, '503 Unavailable'));
  });

  test('fromMap', () {
    expect(new AngelHttpException.fromMap({'status_code': -1, 'message': 'ok'}),
        isException(-1, 'ok'));
  });

  test('toMap = toJson', () {
    var exc = new AngelHttpException.badRequest();
    expect(exc.toMap(), exc.toJson());
    var json_ = json.encode(exc.toJson());
    var exc2 = new AngelHttpException.fromJson(json_);
    expect(exc2.toJson(), exc.toJson());
  });

  test('toString', () {
    expect(
        new AngelHttpException(null, statusCode: 420, message: 'Blaze It')
            .toString(),
        '420: Blaze It');
  });
}

Matcher isException(int statusCode, String message) =>
    new _IsException(statusCode, message);

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
