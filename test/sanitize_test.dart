import 'package:angel_framework/angel_framework.dart';
import 'package:angel_security/angel_security.dart';
import 'package:angel_test/angel_test.dart';
import 'package:angel_validate/server.dart';
import 'package:http_parser/http_parser.dart';
import 'package:logging/logging.dart';
import 'package:matcher/matcher.dart';
import 'package:test/test.dart';
import 'pretty_logging.dart';

final Validator untrustedSchema = Validator({'html*': isString});

main() async {
  Angel app;
  TestClient client;

  setUp(() async {
    app = Angel();
    app.chain([validate(untrustedSchema), sanitizeHtmlInput()])
      ..post('/untrusted', (RequestContext req, ResponseContext res) async {
        String untrusted = req.bodyAsMap['html'];
        res
          ..contentType = MediaType('text', 'html')
          ..write('''
          <!DOCTYPE html>
          <html>
            <head>
              <title>Potential Security Hole</title>
            </head>
            <body>$untrusted</body>
          </html>''');
      })
      ..post('/attribute', (RequestContext req, ResponseContext res) async {
        String untrusted = req.bodyAsMap['html'];
        res
          ..contentType = MediaType('text', 'html')
          ..write('''
          <!DOCTYPE html>
          <html>
            <head>
              <title>Potential Security Hole</title>
            </head>
            <body>
              <img src="$untrusted" />
            </body>
          </html>''');
      });

    app.logger = Logger.detached('angel_security')..onRecord.listen(prettyLog);
    client = await connectTo(app);
  });

  tearDown(() => client.close());

  group('script tag', () {
    test('normal', () async {
      var xss = "<script>alert('XSS')</script>";
      var response = await client.post('/untrusted', body: {'html': xss});
      print(response.body);
      expect(response.body.contains(xss), isFalse);
      expect(response.body.toLowerCase().contains('<script>'), isFalse);
    });

    test('mixed case', () async {
      var xss = "<scRIpT>alert('XSS')</sCRIpt>";
      var response = await client.post('/untrusted', body: {'html': xss});
      print(response.body);
      expect(response.body.contains(xss), isFalse);
      expect(response.body.toLowerCase().contains('<script>'), isFalse);
    });

    test('spaces', () async {
      var xss = "< s c rip t>alert('XSS')</scr ip t>";
      var response = await client.post('/untrusted', body: {'html': xss});
      print(response.body);
      expect(response.body.contains(xss), isFalse);
      expect(response.body.toLowerCase().contains('<script>'), isFalse);
    });

    test('lines', () async {
      var xss = "<scri\npt>\n\nalert('XSS')\t\n</sc\nri\npt>";
      var response = await client.post('/untrusted', body: {'html': xss});
      print(response.body);
      expect(response.body.contains(xss), isFalse);
      expect(response.body.toLowerCase().contains('<script>'), isFalse);
    });

    test('accents', () async {
      var xss = '''<IMG SRC=`javascript:alert("RSnake says, 'XSS'")`>''';
      var response = await client.post('/untrusted', body: {'html': xss});
      print(response.body);
      expect(response.body.contains(xss), isFalse);
      expect(response.body.toLowerCase().contains('<script>'), isFalse);
    });
  });

  test('quotes', () async {
    var xss = '" onclick="<script>alert(\'XSS!\')</script>"';
    var response = await client.post('/attribute', body: {'html': xss});
    print(response.body);
    expect(response.body.contains(xss), isFalse);
    expect(response.body.toLowerCase().contains('<script>'), isFalse);
  });

  test('javascript:evil', () async {
    var xss = 'javascript:alert(\'XSS!\')';
    var response = await client.post('/attribute', body: {'html': xss});
    print(response.body);
    expect(response.body.contains(xss), isFalse);
    expect(response.body.toLowerCase().contains(xss), isFalse);
  });

  test('style attribute', () async {
    var xss = "background-image: url(jaVAscRiPt:alert('XSS'))";
    var response = await client.post('/attribute', body: {'html': xss});
    print(response.body);
    expect(response.body.contains(xss), isFalse);
    expect(response.body.toLowerCase().contains(xss), isFalse);
  });
}
