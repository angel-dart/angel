import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:mock_request/mock_request.dart';
import 'package:test/test.dart';

void main() {
  AngelHttp http;

  setUp(() async {
    var app = new Angel();
    http = new AngelHttp(app);

    app.get('/detach', (req, res) async {
      if (res is HttpResponseContext) {
        var io = await res.detach();
        io
          ..write('Hey!')
          ..close();
      } else {
        throw new StateError('This endpoint only supports HTTP/1.1.');
      }
    });
  });

  tearDown(() => http.close());

  test('detach response', () async {
    var rq = new MockHttpRequest('GET', Uri.parse('/detach'))..close();
    var rs = rq.response;
    await http.handleRequest(rq);
    var body = await rs.transform(utf8.decoder).join();
    expect(body, 'Hey!');
  });
}
