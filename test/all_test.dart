import 'package:angel_client/angel_client.dart';
import 'package:dart2_constant/convert.dart';
import 'package:test/test.dart';
import 'common.dart';

main() {
  var app = new MockAngel();
  Service todoService = app.service('api/todos');

  test('sets method,body,headers,path', () async {
    await app.post('/post', headers: {'method': 'post'}, body: 'post');
    expect(app.client.spec.method, 'POST');
    expect(app.client.spec.path, '/post');
    expect(app.client.spec.headers['method'], 'post');
    expect(await read(app.client.spec.request.finalize()), 'post');
  });

  group('service methods', () {
    test('index', () async {
      await todoService.index();
      expect(app.client.spec.method, 'GET');
      expect(app.client.spec.path, '/api/todos');
    });

    test('read', () async {
      await todoService.read('sleep');
      expect(app.client.spec.method, 'GET');
      expect(app.client.spec.path, '/api/todos/sleep');
    });

    test('create', () async {
      await todoService.create({});
      expect(app.client.spec.method, 'POST');
      expect(app.client.spec.headers['content-type'],
          startsWith('application/json'));
      expect(app.client.spec.path, '/api/todos/');
      expect(await read(app.client.spec.request.finalize()), '{}');
    });

    test('modify', () async {
      await todoService.modify('sleep', {});
      expect(app.client.spec.method, 'PATCH');
      expect(app.client.spec.headers['content-type'],
          startsWith('application/json'));
      expect(app.client.spec.path, '/api/todos/sleep');
      expect(await read(app.client.spec.request.finalize()), '{}');
    });

    test('update', () async {
      await todoService.update('sleep', {});
      expect(app.client.spec.method, 'POST');
      expect(app.client.spec.headers['content-type'],
          startsWith('application/json'));
      expect(app.client.spec.path, '/api/todos/sleep');
      expect(await read(app.client.spec.request.finalize()), '{}');
    });

    test('remove', () async {
      await todoService.remove('sleep');
      expect(app.client.spec.method, 'DELETE');
      expect(app.client.spec.path, '/api/todos/sleep');
    });
  });

  group('authentication', () {
    test('no type, no token throws', () async {
      expect(app.authenticate, throwsArgumentError);
    });

    test('no type defaults to token', () async {
      await app.authenticate(credentials: '<jwt>');
      expect(app.client.spec.path, '/auth/token');
    });

    test('sets type', () async {
      await app.authenticate(type: 'local');
      expect(app.client.spec.path, '/auth/local');
    });

    test('token sends headers', () async {
      await app.authenticate(credentials: '<jwt>');
      expect(app.client.spec.headers['authorization'], 'Bearer <jwt>');
    });

    test('credentials send right body', () async {
      await app
          .authenticate(type: 'local', credentials: {'username': 'password'});
      expect(
        await read(app.client.spec.request.finalize()),
        json.encode({'username': 'password'}),
      );
    });
  });
}
