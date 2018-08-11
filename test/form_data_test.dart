import 'dart:io';
import 'package:body_parser/body_parser.dart';
import 'package:dart2_constant/convert.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'server_test.dart';

main() {
  HttpServer server;
  String url;
  http.Client client;

  setUp(() async {
    server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((HttpRequest request) async {
      //Server will simply return a JSON representation of the parsed body
      // ignore: deprecated_member_use
      request.response.write(jsonEncodeBody(await parseBody(request)));
      await request.response.close();
    });
    url = 'http://localhost:${server.port}';
    print('Test server listening on $url');
    client = new http.Client();
  });

  tearDown(() async {
    await server.close(force: true);
    client.close();
    server = null;
    url = null;
    client = null;
  });

  test('No upload', () async {
    String boundary = 'myBoundary';
    Map<String, String> headers = {
      'content-type': 'multipart/form-data; boundary=$boundary'
    };
    String postData = '''
--$boundary
Content-Disposition: form-data; name="hello"

world
--$boundary--
'''
        .replaceAll("\n", "\r\n");

    print(
        'Form Data: \n${postData.replaceAll("\r", "\\r").replaceAll("\n", "\\n")}');
    var response = await client.post(url, headers: headers, body: postData);
    print('Response: ${response.body}');
    Map jsons = json.decode(response.body);
    var files = jsons['files'].map((map) {
      return map == null
          ? null
          : map.keys.fold<Map<String, dynamic>>(
              <String, dynamic>{}, (out, k) => out..[k.toString()] = map[k]);
    });
    expect(files.length, equals(0));
    expect(jsons['body']['hello'], equals('world'));
  });

  test('Single upload', () async {
    String boundary = 'myBoundary';
    Map<String, String> headers = {
      'content-type': new ContentType("multipart", "form-data",
          parameters: {"boundary": boundary}).toString()
    };
    String postData = '''
--$boundary
Content-Disposition: form-data; name="hello"

world
--$boundary
Content-Disposition: form-data; name="file"; filename="app.dart"
Content-Type: application/dart

Hello world
--$boundary--
'''
        .replaceAll("\n", "\r\n");

    print(
        'Form Data: \n${postData.replaceAll("\r", "\\r").replaceAll("\n", "\\n")}');
    var response = await client.post(url, headers: headers, body: postData);
    print('Response: ${response.body}');
    Map jsons = json.decode(response.body);
    var files = jsons['files'];
    expect(files.length, equals(1));
    expect(files[0]['name'], equals('file'));
    expect(files[0]['mimeType'], equals('application/dart'));
    expect(files[0]['data'].length, equals(11));
    expect(files[0]['filename'], equals('app.dart'));
    expect(jsons['body']['hello'], equals('world'));
  });

  test('Multiple upload', () async {
    String boundary = 'myBoundary';
    Map<String, String> headers = {
      'content-type': 'multipart/form-data; boundary=$boundary'
    };
    String postData = '''
--$boundary
Content-Disposition: form-data; name="json"

god
--$boundary
Content-Disposition: form-data; name="num"

14.50000
--$boundary
Content-Disposition: form-data; name="file"; filename="app.dart"
Content-Type: text/plain

Hello world
--$boundary
Content-Disposition: form-data; name="entry-point"; filename="main.js"
Content-Type: text/javascript

function main() {
  console.log("Hello, world!");
}
--$boundary--
'''
        .replaceAll("\n", "\r\n");

    print(
        'Form Data: \n${postData.replaceAll("\r", "\\r").replaceAll("\n", "\\n")}');
    var response = await client.post(url, headers: headers, body: postData);
    print('Response: ${response.body}');
    Map jsons = json.decode(response.body);
    var files = jsons['files'];
    expect(files.length, equals(2));
    expect(files[0]['name'], equals('file'));
    expect(files[0]['mimeType'], equals('text/plain'));
    expect(files[0]['data'].length, equals(11));
    expect(files[1]['name'], equals('entry-point'));
    expect(files[1]['mimeType'], equals('text/javascript'));
    expect(jsons['body']['json'], equals('god'));
    expect(jsons['body']['num'], equals(14.5));
  });
}
