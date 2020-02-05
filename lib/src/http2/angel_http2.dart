import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart' hide Header;
import 'package:angel_framework/http.dart';
import 'package:http2/transport.dart';
import 'package:mock_request/mock_request.dart';
import 'http2_request_context.dart';
import 'http2_response_context.dart';
import 'package:uuid/uuid.dart';

/// Boots a shared server instance. Use this if launching multiple isolates.
Future<SecureServerSocket> startSharedHttp2(
    address, int port, SecurityContext ctx) {
  return SecureServerSocket.bind(address, port, ctx, shared: true);
}

/// Adapts `package:http2`'s [ServerTransportConnection] to serve Angel.
class AngelHttp2 extends Driver<Socket, ServerTransportStream,
    SecureServerSocket, Http2RequestContext, Http2ResponseContext> {
  final ServerSettings settings;
  AngelHttp _http;
  final StreamController<HttpRequest> _onHttp1 = StreamController();
  final Map<String, MockHttpSession> _sessions = {};
  final Uuid _uuid = Uuid();
  _AngelHttp2ServerSocket _artificial;

  SecureServerSocket get socket => _artificial;

  AngelHttp2._(
      Angel app,
      Future<SecureServerSocket> Function(dynamic, int) serverGenerator,
      bool useZone,
      bool allowHttp1,
      this.settings)
      : super(
          app,
          serverGenerator,
          useZone: useZone,
        ) {
    if (allowHttp1) {
      _http = AngelHttp(app, useZone: useZone);
      onHttp1.listen(_http.handleRequest);
    }
  }

  factory AngelHttp2(Angel app, SecurityContext securityContext,
      {bool useZone = true, bool allowHttp1 = false, ServerSettings settings}) {
    return AngelHttp2.custom(app, securityContext, SecureServerSocket.bind,
        allowHttp1: allowHttp1, settings: settings);
  }

  factory AngelHttp2.custom(
      Angel app,
      SecurityContext ctx,
      Future<SecureServerSocket> serverGenerator(
          address, int port, SecurityContext ctx),
      {bool useZone = true,
      bool allowHttp1 = false,
      ServerSettings settings}) {
    return AngelHttp2._(app, (address, port) {
      var addr = address is InternetAddress
          ? address
          : InternetAddress(address.toString());
      return Future.sync(() => serverGenerator(addr, port, ctx));
    }, useZone, allowHttp1, settings);
  }

  /// Fires when an HTTP/1.x request is received.
  Stream<HttpRequest> get onHttp1 => _onHttp1.stream;

  @override
  Future<SecureServerSocket> generateServer([address, int port]) async {
    var s = await serverGenerator(address ?? '127.0.0.1', port ?? 0);
    return _artificial = _AngelHttp2ServerSocket(s, this);
  }

  @override
  Future<SecureServerSocket> close() async {
    await _artificial.close();
    await _http?.close();
    return await super.close();
  }

  @override
  void addCookies(ServerTransportStream response, Iterable<Cookie> cookies) {
    var headers =
        cookies.map((cookie) => Header.ascii('set-cookie', cookie.toString()));
    response.sendHeaders(headers.toList());
  }

  @override
  Future closeResponse(ServerTransportStream response) {
    response.terminate();
    return Future.value();
  }

  @override
  Future<Http2RequestContext> createRequestContext(
      Socket request, ServerTransportStream response) {
    return Http2RequestContext.from(response, request, app, _sessions, _uuid);
  }

  @override
  Future<Http2ResponseContext> createResponseContext(
      Socket request, ServerTransportStream response,
      [Http2RequestContext correspondingRequest]) async {
    return Http2ResponseContext(app, response, correspondingRequest)
      ..encoders.addAll(app.encoders);
  }

  @override
  Stream<ServerTransportStream> createResponseStreamFromRawRequest(
      Socket request) {
    var connection =
        ServerTransportConnection.viaSocket(request, settings: settings);
    return connection.incomingStreams;
  }

  @override
  void setChunkedEncoding(ServerTransportStream response, bool value) {
    // Do nothing in HTTP/2
  }

  @override
  void setContentLength(ServerTransportStream response, int length) {
    setHeader(response, 'content-length', length.toString());
  }

  @override
  void setHeader(ServerTransportStream response, String key, String value) {
    response.sendHeaders([Header.ascii(key, value)]);
  }

  @override
  void setStatusCode(ServerTransportStream response, int value) {
    response.sendHeaders([Header.ascii(':status', value.toString())]);
  }

  @override
  Uri get uri => Uri(
      scheme: 'https',
      host: server.address.address,
      port: server.port != 443 ? server.port : null);

  @override
  void writeStringToResponse(ServerTransportStream response, String value) {
    writeToResponse(response, utf8.encode(value));
  }

  @override
  void writeToResponse(ServerTransportStream response, List<int> data) {
    response.sendData(data);
  }
}

class _FakeServerSocket extends Stream<Socket> implements ServerSocket {
  final _AngelHttp2ServerSocket angel;
  final _ctrl = StreamController<Socket>();

  _FakeServerSocket(this.angel);

  @override
  InternetAddress get address => angel.address;

  @override
  Future<ServerSocket> close() async {
    (_ctrl.close());
    return this;
  }

  @override
  int get port => angel.port;

  @override
  StreamSubscription<Socket> listen(void Function(Socket event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    return _ctrl.stream.listen(onData,
        cancelOnError: cancelOnError, onError: onError, onDone: onDone);
  }
}

class _AngelHttp2ServerSocket extends Stream<SecureSocket>
    implements SecureServerSocket {
  final SecureServerSocket socket;
  final AngelHttp2 driver;
  final _ctrl = StreamController<SecureSocket>();
  _FakeServerSocket _fake;
  StreamSubscription _sub;

  _AngelHttp2ServerSocket(this.socket, this.driver) {
    _fake = _FakeServerSocket(this);
    HttpServer.listenOn(_fake).pipe(driver._onHttp1);
    _sub = socket.listen(
      (socket) {
        if (socket.selectedProtocol == null ||
            socket.selectedProtocol == 'http/1.0' ||
            socket.selectedProtocol == 'http/1.1') {
          _fake._ctrl.add(socket);
        } else if (socket.selectedProtocol == 'h2' ||
            socket.selectedProtocol == 'h2-14') {
          _ctrl.add(socket);
        } else {
          socket.destroy();
          throw Exception(
              'AngelHttp2 does not support ${socket.selectedProtocol} as an ALPN protocol.');
        }
      },
      onDone: _ctrl.close,
      onError: (e, st) {
        driver.app.logger.warning(
            'HTTP/2 incoming connection failure: ', e, st as StackTrace);
      },
    );
  }

  InternetAddress get address => socket.address;

  int get port => socket.port;

  Future<SecureServerSocket> close() {
    _sub?.cancel();
    _fake.close();
    _ctrl.close();
    return socket.close();
  }

  @override
  StreamSubscription<SecureSocket> listen(
      void Function(SecureSocket event) onData,
      {Function onError,
      void Function() onDone,
      bool cancelOnError}) {
    return _ctrl.stream.listen(onData,
        cancelOnError: cancelOnError, onError: onError, onDone: onDone);
  }
}
