import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:http2/transport.dart';

/// Simple HTTP/2 client
class Http2Client extends BaseClient {
  static Future<ClientTransportStream> convertRequestToStream(
      BaseRequest request) async {
    // Connect a socket
    var socket = await SecureSocket.connect(
      request.url.host,
      request.url.port ?? 443,
      onBadCertificate: (_) => true,
      supportedProtocols: ['h2'],
    );

    var connection = ClientTransportConnection.viaSocket(socket);

    var headers = <Header>[
      Header.ascii(':authority', request.url.authority),
      Header.ascii(':method', request.method),
      Header.ascii(
          ':path',
          request.url.path +
              (request.url.hasQuery ? ('?' + request.url.query) : '')),
      Header.ascii(':scheme', request.url.scheme),
    ];

    var bb = await request
        .finalize()
        .fold<BytesBuilder>(BytesBuilder(), (out, list) => out..add(list));
    var body = bb.takeBytes();

    if (body.isNotEmpty) {
      headers.add(Header.ascii('content-length', body.length.toString()));
    }

    request.headers.forEach((k, v) {
      headers.add(Header.ascii(k, v));
    });

    var stream = await connection.makeRequest(headers, endStream: body.isEmpty);

    if (body.isNotEmpty) {
      stream.sendData(body, endStream: true);
    } else {
      (stream.outgoingMessages.close());
    }

    return stream;
  }

  /// Returns `true` if the response stream was closed.
  static Future<bool> readResponse(ClientTransportStream stream,
      Map<String, String> headers, BytesBuilder body) {
    var c = Completer<bool>();
    var closed = false;

    stream.incomingMessages.listen(
      (msg) {
        if (msg is HeadersStreamMessage) {
          for (var header in msg.headers) {
            var name = ascii.decode(header.name).toLowerCase(),
                value = ascii.decode(header.value);
            headers[name] = value;
            //print('$name: $value');
          }
        } else if (msg is DataStreamMessage) {
          body.add(msg.bytes);
        }

        if (!closed && msg.endStream) closed = true;
      },
      cancelOnError: true,
      onError: c.completeError,
      onDone: () => c.complete(closed),
    );

    return c.future;
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    var stream = await convertRequestToStream(request);
    var headers = <String, String>{};
    var body = BytesBuilder();
    var closed = await readResponse(stream, headers, body);
    return StreamedResponse(
      Stream.fromIterable([body.takeBytes()]),
      int.parse(headers[':status']),
      headers: headers,
      isRedirect: headers.containsKey('location'),
      contentLength: headers.containsKey('content-length')
          ? int.parse(headers['content-length'])
          : null,
      request: request,
      reasonPhrase: null,
      // doesn't exist in HTTP/2
      persistentConnection: !closed,
    );
  }
}
