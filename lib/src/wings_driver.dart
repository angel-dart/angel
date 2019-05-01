import 'dart:async';
import 'dart:convert';
import 'dart:io' show Cookie;
import 'dart:typed_data';
import 'package:angel_framework/angel_framework.dart';
import 'wings_request.dart';
import 'wings_response.dart';
import 'wings_socket.dart';

Future<WingsSocket> startSharedWings(dynamic addr, int port) {
  return WingsSocket.bind(addr, port, shared: true);
}

class AngelWings extends Driver<WingsClientSocket, int, WingsSocket,
    WingsRequestContext, WingsResponseContext> {
  factory AngelWings(Angel app) {
    return AngelWings.custom(app, WingsSocket.bind);
  }

  AngelWings.custom(
      Angel app, Future<WingsSocket> Function(dynamic, int) serverGenerator)
      : super(app, serverGenerator);

  @override
  void addCookies(int response, Iterable<Cookie> cookies) {
    for (var cookie in cookies) {
      setHeader(response, 'set-cookie', cookie.toString());
    }
  }

  @override
  Future<WingsSocket> close() async {
    await server?.close();
    return super.close();
  }

  @override
  Future closeResponse(int response) {
    closeNativeSocketDescriptor(response);
    return Future.value();
  }

  @override
  Future<WingsRequestContext> createRequestContext(
      WingsClientSocket request, int response) {
    return WingsRequestContext.from(app, request);
  }

  @override
  Future<WingsResponseContext> createResponseContext(
      WingsClientSocket request, int response,
      [WingsRequestContext correspondingRequest]) {
    return Future.value(WingsResponseContext(
        app, request.fileDescriptor, correspondingRequest));
  }

  @override
  Stream<int> createResponseStreamFromRawRequest(WingsClientSocket request) {
    return Stream.fromIterable([request.fileDescriptor]);
  }

  @override
  void setChunkedEncoding(int response, bool value) {
    // TODO: implement setChunkedEncoding
  }

  @override
  void setContentLength(int response, int length) {
    writeStringToResponse(response, 'content-length: $length\r\n');
  }

  @override
  void setHeader(int response, String key, String value) {
    writeStringToResponse(response, '$key: $value\r\n');
  }

  @override
  void setStatusCode(int response, int value) {
    // HTTP-Version SP Status-Code SP Reason-Phrase CRLF
    writeStringToResponse(response, 'HTTP/1.1 $value\r\n');
  }

  @override
  Uri get uri {
    return Uri(scheme: 'http', host: server.address.address, port: server.port);
  }

  @override
  void writeStringToResponse(int response, String value) {
    writeToResponse(response, utf8.encode(value));
  }

  @override
  void writeToResponse(int response, List<int> data) {
    var buf = data is Uint8List ? data : Uint8List.fromList(data);
    writeToNativeSocket(response, buf);
  }
}
