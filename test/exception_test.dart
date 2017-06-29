import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:matcher/matcher.dart';
import 'package:test/test.dart';

main() {
  test('named constructors', () {
    expect(new AngelHttpException.badRequest(),
        isException(HttpStatus.BAD_REQUEST, '400 Bad Request'));
    expect(new AngelHttpException.BadRequest(),
        isException(HttpStatus.BAD_REQUEST, '400 Bad Request'));
    expect(new AngelHttpException.notAuthenticated(),
        isException(HttpStatus.UNAUTHORIZED, '401 Not Authenticated'));
    expect(new AngelHttpException.NotAuthenticated(),
        isException(HttpStatus.UNAUTHORIZED, '401 Not Authenticated'));
    expect(new AngelHttpException.paymentRequired(),
        isException(HttpStatus.PAYMENT_REQUIRED, '402 Payment Required'));
    expect(new AngelHttpException.PaymentRequired(),
        isException(HttpStatus.PAYMENT_REQUIRED, '402 Payment Required'));
    expect(new AngelHttpException.forbidden(),
        isException(HttpStatus.FORBIDDEN, '403 Forbidden'));
    expect(new AngelHttpException.Forbidden(),
        isException(HttpStatus.FORBIDDEN, '403 Forbidden'));
    expect(new AngelHttpException.notFound(),
        isException(HttpStatus.NOT_FOUND, '404 Not Found'));
    expect(new AngelHttpException.NotFound(),
        isException(HttpStatus.NOT_FOUND, '404 Not Found'));
    expect(new AngelHttpException.methodNotAllowed(),
        isException(HttpStatus.METHOD_NOT_ALLOWED, '405 Method Not Allowed'));
    expect(new AngelHttpException.MethodNotAllowed(),
        isException(HttpStatus.METHOD_NOT_ALLOWED, '405 Method Not Allowed'));
    expect(new AngelHttpException.notAcceptable(),
        isException(HttpStatus.NOT_ACCEPTABLE, '406 Not Acceptable'));
    expect(new AngelHttpException.NotAcceptable(),
        isException(HttpStatus.NOT_ACCEPTABLE, '406 Not Acceptable'));
    expect(new AngelHttpException.methodTimeout(),
        isException(HttpStatus.REQUEST_TIMEOUT, '408 Timeout'));
    expect(new AngelHttpException.MethodTimeout(),
        isException(HttpStatus.REQUEST_TIMEOUT, '408 Timeout'));
    expect(new AngelHttpException.conflict(),
        isException(HttpStatus.CONFLICT, '409 Conflict'));
    expect(new AngelHttpException.Conflict(),
        isException(HttpStatus.CONFLICT, '409 Conflict'));
    expect(new AngelHttpException.notProcessable(),
        isException(422, '422 Not Processable'));
    expect(new AngelHttpException.NotProcessable(),
        isException(422, '422 Not Processable'));
    expect(new AngelHttpException.notImplemented(),
        isException(HttpStatus.NOT_IMPLEMENTED, '501 Not Implemented'));
    expect(new AngelHttpException.NotImplemented(),
        isException(HttpStatus.NOT_IMPLEMENTED, '501 Not Implemented'));
    expect(new AngelHttpException.unavailable(),
        isException(HttpStatus.SERVICE_UNAVAILABLE, '503 Unavailable'));
    expect(new AngelHttpException.Unavailable(),
        isException(HttpStatus.SERVICE_UNAVAILABLE, '503 Unavailable'));
  });

  test('fromMap', () {
    expect(new AngelHttpException.fromMap({'status_code': -1, 'message': 'ok'}),
        isException(-1, 'ok'));
  });

  test('toMap = toJson', () {
    var exc = new AngelHttpException.badRequest();
    expect(exc.toMap(), exc.toJson());
    var json = JSON.encode(exc.toJson());
    var exc2 = new AngelHttpException.fromJson(json);
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
  bool matches(AngelHttpException item, Map matchState) {
    return item.statusCode == statusCode && item.message == message;
  }
}
