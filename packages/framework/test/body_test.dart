import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:mock_request/mock_request.dart';
import 'package:test/test.dart';

void main() {
  var app = Angel();
  var http = AngelHttp(app);

  Future<RequestContext> request(
      {bool asJson = true,
      bool parse = true,
      Map<String, dynamic> bodyFields,
      List bodyList}) async {
    var rq = MockHttpRequest('POST', Uri(path: '/'));

    if (bodyFields != null) {
      if (asJson) {
        rq
          ..headers.contentType = ContentType('application', 'json')
          ..write(json.encode(bodyFields));
      } else {
        var b = StringBuffer();
        var i = 0;
        for (var entry in bodyFields.entries) {
          if (i++ > 0) b.write('&');
          b.write(entry.key);
          b.write('=');
          b.write(Uri.encodeComponent(entry.value.toString()));
        }

        rq
          ..headers.contentType =
              ContentType('application', 'x-www-form-urlencoded')
          ..write(json.encode(b.toString()));
      }
    } else if (bodyList != null) {
      rq
        ..headers.contentType = ContentType('application', 'json')
        ..write(json.encode(bodyList));
    }

    await rq.close();
    var req = await http.createRequestContext(rq, rq.response);
    if (parse) await req.parseBody();
    return req;
  }

  test('parses json maps', () async {
    var req = await request(bodyFields: {'hello': 'world'});
    expect(req.bodyAsObject, TypeMatcher<Map<String, dynamic>>());
    expect(req.bodyAsMap, {'hello': 'world'});
  });

  test('parses json lists', () async {
    var req = await request(bodyList: ['foo', 'bar']);
    expect(req.bodyAsObject, TypeMatcher<List>());
    expect(req.bodyAsList, ['foo', 'bar']);
  });

  test('deserializeBody', () async {
    var req = await request(
        asJson: true, bodyFields: {'text': 'Hey', 'complete': false});
    var todo = await req.deserializeBody(Todo.fromMap);
    expect(todo.text, 'Hey');
    expect(todo.completed, false);
  });

  test('decodeBody', () async {
    var req = await request(
        asJson: true, bodyFields: {'text': 'Hey', 'complete': false});
    var todo = await req.decodeBody(TodoCodec());
    expect(todo.text, 'Hey');
    expect(todo.completed, false);
  });

  test('throws when body has not been parsed', () async {
    var req = await request(parse: false);
    expect(() => req.bodyAsObject, throwsStateError);
    expect(() => req.bodyAsMap, throwsStateError);
    expect(() => req.bodyAsList, throwsStateError);
  });

  test('can set body object exactly once', () async {
    var req = await request(parse: false);
    req.bodyAsObject = 23;
    expect(req.bodyAsObject, 23);
    expect(() => req.bodyAsObject = {45.6: '34'}, throwsStateError);
  });

  test('can set body map exactly once', () async {
    var req = await request(parse: false);
    req.bodyAsMap = {'hey': 'yes'};
    expect(req.bodyAsMap, {'hey': 'yes'});
    expect(() => req.bodyAsMap = {'hm': 'ok'}, throwsStateError);
  });

  test('can set body list exactly once', () async {
    var req = await request(parse: false);
    req.bodyAsList = [
      {'hey': 'yes'}
    ];
    expect(req.bodyAsList, [
      {'hey': 'yes'}
    ]);
    expect(
        () => req.bodyAsList = [
              {'hm': 'ok'}
            ],
        throwsStateError);
  });
}

class Todo {
  String text;
  bool completed;

  Todo({this.text, this.completed});

  static Todo fromMap(Map m) =>
      Todo(text: m['text'] as String, completed: m['complete'] as bool);
}

class TodoCodec extends Codec<Todo, Map> {
  @override
  Converter<Map, Todo> get decoder => TodoDecoder();

  @override
  Converter<Todo, Map> get encoder => throw UnsupportedError('no encoder');
}

class TodoDecoder extends Converter<Map, Todo> {
  @override
  Todo convert(Map input) => Todo.fromMap(input);
}
