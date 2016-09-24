import 'dart:async';
import 'dart:io';
import 'body_parse_result.dart';

class BodyParser implements StreamTransformer<List<int>, BodyParseResult> {

  @override
  Stream<BodyParseResult> bind(HttpRequest stream) {
    var _stream = new StreamController<BodyParseResult>();

    stream.toList().then((lists) {
      var ints = [];
      lists.forEach(ints.addAll);
      _stream.close();


    });

    return _stream.stream;
  }
}