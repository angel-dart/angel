import 'dart:async';
import 'dart:convert';
import 'dart:io' show Cookie;
import 'dart:typed_data';
import 'package:angel_framework/angel_framework.dart';
import 'wings_request.dart';
import 'wings_response.dart';
import 'wings_socket.dart';

class AngelWings extends Driver<int, int, WingsSocket, WingsRequestContext,
    WingsResponseContext> {
  factory AngelWings(Angel app) {
    return AngelWings._(app, WingsSocket.bind);
  }

  AngelWings._(
      Angel app, Future<WingsSocket> Function(dynamic, int) serverGenerator)
      : super(app, serverGenerator);

  @override
  void addCookies(int response, Iterable<Cookie> cookies) {
    for (var cookie in cookies) {
      setHeader(response, 'set-cookie', cookie.toString());
    }
  }

  @override
  Future closeResponse(int response) {
    closeNativeSocketDescriptor(response);
    return Future.value();
  }

  @override
  Future<WingsRequestContext> createRequestContext(int request, int response) {
    // TODO: implement createRequestContext
    return null;
  }

  @override
  Future<WingsResponseContext> createResponseContext(int request, int response,
      [WingsRequestContext correspondingRequest]) {
    // TODO: implement createResponseContext
    return null;
  }

  @override
  Stream<int> createResponseStreamFromRawRequest(int request) {
    return Stream.fromIterable([request]);
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
  // TODO: implement uri
  Uri get uri => null;

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
