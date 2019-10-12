import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart' hide Header;
import 'package:angel_framework/http2.dart';
import 'package:http/src/multipart_file.dart' as http;
import 'package:http/src/multipart_request.dart' as http;
import 'package:http/io_client.dart';
import 'package:http2/transport.dart';
import 'package:http_parser/http_parser.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'http2_client.dart';

const String jfk =
    'Ask not what your country can do for you, but what you can do for your country.';

Stream<List<int>> jfkStream() {
  return Stream.fromIterable([utf8.encode(jfk)]);
}

void main() {
  var client = Http2Client();
  IOClient h1c;
  Angel app;
  AngelHttp2 http2;
  Uri serverRoot;

  setUp(() async {
    app = Angel(reflector: MirrorsReflector())..encoders['gzip'] = gzip.encoder;
    hierarchicalLoggingEnabled = true;
    app.logger = Logger.detached('angel.http2')
      ..onRecord.listen((rec) {
        print(rec);
        if (rec.error == null) return;
        print(rec.error);
        if (rec.stackTrace != null) print(rec.stackTrace);
      });

    app.get('/', (req, res) async {
      res.write('Hello world');
      await res.close();
    });

    app.all('/method', (req, res) => req.method);

    app.get('/json', (_, __) => {'foo': 'bar'});

    app.get('/stream', (req, res) => jfkStream().pipe(res));

    app.get('/headers', (req, res) async {
      res.headers.addAll({'foo': 'bar', 'x-angel': 'http2'});
      await res.close();
    });

    app.get('/status', (req, res) async {
      res.statusCode = 1337;
      await res.close();
    });

    app.post('/body', (req, res) => req.parseBody().then((_) => req.bodyAsMap));

    app.post('/upload', (req, res) async {
      await req.parseBody();
      var body = req.bodyAsMap, files = req.uploadedFiles;
      var file = files.firstWhere((f) => f.name == 'file');
      return [
        await file.data.map((l) => l.length).reduce((a, b) => a + b),
        file.contentType.mimeType,
        body
      ];
    });

    app.get('/push', (req, res) async {
      res.write('ok');

      if (res is Http2ResponseContext && res.canPush) {
        var a = res.push('a')..write('a');
        await a.close();

        var b = res.push('b')..write('b');
        await b.close();
      }

      await res.close();
    });

    app.get('/param/:name', (req, res) => req.params);

    app.get('/query', (req, res) {
      print('incoming URI: ${req.uri}');
      return req.queryParameters;
    });

    var ctx = SecurityContext()
      ..useCertificateChain('dev.pem')
      ..usePrivateKey('dev.key', password: 'dartdart')
      ..setAlpnProtocols(['h2'], true);

    // Create an HTTP client that trusts our server.
    h1c = IOClient(HttpClient()..badCertificateCallback = (_, __, ___) => true);

    http2 = AngelHttp2(app, ctx, allowHttp1: true);

    var server = await http2.startServer();
    serverRoot = Uri.parse('https://127.0.0.1:${server.port}');
  });

  tearDown(() async {
    await http2.close();
    await h1c.close();
  });

  test('buffered response', () async {
    var response = await client.get(serverRoot);
    expect(response.body, 'Hello world');
  });

  test('allowHttp1', () async {
    var response = await h1c.get(serverRoot);
    expect(response.body, 'Hello world');
  });

  test('streamed response', () async {
    var response = await client.get(serverRoot.replace(path: '/stream'));
    expect(response.body, jfk);
  });

  group('gzip', () {
    test('buffered response', () async {
      var response = await client
          .get(serverRoot, headers: {'accept-encoding': 'gzip, deflate, br'});
      expect(response.headers['content-encoding'], 'gzip');
      var decoded = gzip.decode(response.bodyBytes);
      expect(utf8.decode(decoded), 'Hello world');
    });

    test('streamed response', () async {
      var response = await client.get(serverRoot.replace(path: '/stream'),
          headers: {'accept-encoding': 'gzip'});
      expect(response.headers['content-encoding'], 'gzip');
      //print(response.body);
      var decoded = gzip.decode(response.bodyBytes);
      expect(utf8.decode(decoded), jfk);
    });
  });

  test('query uri decoded', () async {
    var uri =
        serverRoot.replace(path: '/query', queryParameters: {'foo!': 'bar?'});
    var response = await client.get(uri);
    print('Sent $uri');
    expect(response.body, json.encode({'foo!': 'bar?'}));
  });

  test('params uri decoded', () async {
    var response = await client.get(serverRoot.replace(path: '/param/foo!'));
    expect(response.body, json.encode({'name': 'foo!'}));
  });

  test('method parsed', () async {
    var response = await client.delete(serverRoot.replace(path: '/method'));
    expect(response.body, json.encode('DELETE'));
  });

  test('json response', () async {
    var response = await client.get(serverRoot.replace(path: '/json'));
    expect(response.body, json.encode({'foo': 'bar'}));
    expect(ContentType.parse(response.headers['content-type']).mimeType,
        ContentType.json.mimeType);
  });

  test('status sent', () async {
    var response = await client.get(serverRoot.replace(path: '/status'));
    expect(response.statusCode, 1337);
  });

  test('headers sent', () async {
    var response = await client.get(serverRoot.replace(path: '/headers'));
    expect(response.headers['foo'], 'bar');
    expect(response.headers['x-angel'], 'http2');
  });

  test('server push', () async {
    var socket = await SecureSocket.connect(
      serverRoot.host,
      serverRoot.port ?? 443,
      onBadCertificate: (_) => true,
      supportedProtocols: ['h2'],
    );

    var connection = ClientTransportConnection.viaSocket(
      socket,
      settings: ClientSettings(allowServerPushes: true),
    );

    var headers = <Header>[
      Header.ascii(':authority', serverRoot.authority),
      Header.ascii(':method', 'GET'),
      Header.ascii(':path', serverRoot.replace(path: '/push').path),
      Header.ascii(':scheme', serverRoot.scheme),
    ];

    var stream = await connection.makeRequest(headers, endStream: true);

    var bb = await stream.incomingMessages
        .where((s) => s is DataStreamMessage)
        .cast<DataStreamMessage>()
        .fold<BytesBuilder>(BytesBuilder(), (out, msg) => out..add(msg.bytes));

    // Check that main body was sent
    expect(utf8.decode(bb.takeBytes()), 'ok');

    var pushes = await stream.peerPushes.toList();
    expect(pushes, hasLength(2));

    var pushA = pushes[0], pushB = pushes[1];

    String getPath(TransportStreamPush p) => ascii.decode(p.requestHeaders
        .firstWhere((h) => ascii.decode(h.name) == ':path')
        .value);

    /*
    Future<String> getBody(ClientTransportStream stream) async {
      await stream.outgoingMessages.close();
      var bb = await stream.incomingMessages
          .map((s) {
            if (s is HeadersStreamMessage) {
              for (var h in s.headers) {
                print('${ASCII.decode(h.name)}: ${ASCII.decode(h.value)}');
              }
            } else if (s is DataStreamMessage) {
              print(UTF8.decode(s.bytes));
            }

            return s;
          })
          .where((s) => s is DataStreamMessage)
          .cast<DataStreamMessage>()
          .fold<BytesBuilder>(
              BytesBuilder(), (out, msg) => out..add(msg.bytes));
      return UTF8.decode(bb.takeBytes());
    }
    */

    expect(getPath(pushA), '/a');
    expect(getPath(pushB), '/b');

    // However, Chrome, Firefox, Edge all can
    //expect(await getBody(pushA.stream), 'a');
    //expect(await getBody(pushB.stream), 'b');
  });

  group('body parsing', () {
    test('urlencoded body parsed', () async {
      var response = await client.post(
        serverRoot.replace(path: '/body'),
        headers: {
          'accept': 'application/json',
          'content-type': 'application/x-www-form-urlencoded'
        },
        body: 'foo=bar',
      );
      expect(response.body, json.encode({'foo': 'bar'}));
    });

    test('json body parsed', () async {
      var response = await client.post(serverRoot.replace(path: '/body'),
          headers: {
            'accept': 'application/json',
            'content-type': 'application/json'
          },
          body: json.encode({'foo': 'bar'}));
      expect(response.body, json.encode({'foo': 'bar'}));
    });

    test('multipart body parsed', () async {
      var rq =
          http.MultipartRequest('POST', serverRoot.replace(path: '/upload'));
      rq.headers.addAll({'accept': 'application/json'});

      rq.fields['foo'] = 'bar';
      rq.files.add(http.MultipartFile(
          'file', Stream.fromIterable([utf8.encode('hello world')]), 11,
          contentType: MediaType('angel', 'framework')));

      var response = await client.send(rq);
      var responseBody = await response.stream.transform(utf8.decoder).join();

      expect(
          responseBody,
          json.encode([
            11,
            'angel/framework',
            {'foo': 'bar'}
          ]));
    });
  });
}
