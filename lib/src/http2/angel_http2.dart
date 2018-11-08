import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart' hide Header;
import 'package:combinator/combinator.dart';
import 'package:http2/src/artificial_server_socket.dart';
import 'package:http2/transport.dart';
import 'package:mock_request/mock_request.dart';
import 'http2_request_context.dart';
import 'http2_response_context.dart';
import 'package:pool/pool.dart';
import 'package:uuid/uuid.dart';
import 'package:tuple/tuple.dart';

class AngelHttp2 extends Driver<Socket, ServerTransportStream,
    ArtificialServerSocket, Http2RequestContext, Http2ResponseContext> {
  final ServerSettings settings;
  final StreamController<HttpRequest> _onHttp1 = new StreamController();
  final Map<String, MockHttpSession> _sessions = {};
  final Uuid _uuid = new Uuid();
  ArtificialServerSocket _artificial;
  HttpServer _httpServer;
  StreamController<SecureSocket> _http1;
  SecureServerSocket _socket;
  StreamSubscription _sub;

  AngelHttp2._(
      Angel app,
      Future<ArtificialServerSocket> Function(dynamic, int) serverGenerator,
      bool useZone,
      this.settings)
      : super(app, serverGenerator, useZone: useZone);

  factory AngelHttp2(Angel app, SecurityContext securityContext,
      {bool useZone: true, ServerSettings settings}) {
    return new AngelHttp2.custom(app, securityContext, SecureServerSocket.bind,
        settings: settings);
  }

  factory AngelHttp2.custom(
      Angel app,
      SecurityContext ctx,
      Future<SecureServerSocket> serverGenerator(
          address, int port, SecurityContext ctx),
      {bool useZone: true,
      ServerSettings settings}) {
    return new AngelHttp2._(app, (address, port) {
      var addr = address is InternetAddress
          ? address
          : new InternetAddress(address.toString());
      return SecureServerSocket.bind(addr, port, ctx)
          .then((s) => ArtificialServerSocket(addr, port, s));
    }, useZone, settings);
  }

  /// Fires when an HTTP/1.x request is received.
  Stream<HttpRequest> get onHttp1 => _onHttp1.stream;

  @override
  void addCookies(ServerTransportStream response, Iterable<Cookie> cookies) {
    var headers = cookies
        .map((cookie) => new Header.ascii('set-cookie', cookie.toString()));
    response.sendHeaders(headers.toList());
  }

  @override
  Future closeResponse(ServerTransportStream response) {
    response.terminate();
    return new Future.value();
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
    return new Http2ResponseContext(app, response, correspondingRequest)
      ..encoders.addAll(app.encoders);
  }

  @override
  ServerTransportStream createResponseFromRawRequest(Socket request) {
    var connection =
        new ServerTransportConnection.viaSocket(request, settings: settings);
  }

  @override
  Uri getUriFromRequest(Socket request) {
    // TODO: implement getUriFromRequest
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
    response.sendHeaders([new Header.ascii(key, value)]);
  }

  @override
  void setStatusCode(ServerTransportStream response, int value) {
    response.sendHeaders([new Header.ascii(':status', value.toString())]);
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
