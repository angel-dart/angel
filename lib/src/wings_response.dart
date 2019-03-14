import 'dart:async';

import 'dart:io';

import 'package:angel_framework/angel_framework.dart';

class WingsResponseContext extends ResponseContext {
  @override
  void add(List<int> event) {
    // TODO: implement add
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    // TODO: implement addStream
    return null;
  }

  @override
  // TODO: implement buffer
  BytesBuilder get buffer => null;

  @override
  // TODO: implement correspondingRequest
  RequestContext get correspondingRequest => null;

  @override
  FutureOr detach() {
    // TODO: implement detach
    return null;
  }

  @override
  // TODO: implement isBuffered
  bool get isBuffered => null;

  @override
  // TODO: implement isOpen
  bool get isOpen => null;

  @override
  // TODO: implement rawResponse
  get rawResponse => null;

  @override
  void useBuffer() {
    // TODO: implement useBuffer
  }

}