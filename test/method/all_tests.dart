import 'package:angel_route/angel_route.dart';
import 'package:test/test.dart';

main() {
  var router = new Router(debug: true);
  final getFoo = router.get('/foo', 'GET');
  final postFoo = router.post('/foo', 'POST');

  Route getFooBar, postFooBar, patchFooBarId;

  router.group('/foo/bar', (router) {
    getFooBar = router.get('/', 'GET');
    postFooBar = router.post('/', 'POST');
    patchFooBarId = router.patch('/:id([0-9]+)', 'PATCH');
  });

  final Router books = new Router();

  final getBooks = books.get('/', 'GET');
  final postBooks = books.post('/', 'POST');
  final getBooksFoo = books.get('/foo', 'GET');
  final postBooksFoo = books.post('/foo', 'POST');

  Route getBooksChapters,
      postBooksChapters,
      getBooksChaptersReviews,
      postBooksChaptersReviews;

  books.group('/:id/chapters', (router) {
    getBooksChapters = router.get('/', 'GET');
    postBooksChapters = router.post('/', 'POST');

    router.group('/:id([A-Za-z]+)/reviews', (router) {
      getBooksChaptersReviews = router.get('/', 'GET');
      postBooksChaptersReviews = router.post('/', 'POST');
    });
  });

  router.mount('/books', books);
  router.normalize();

  group('top level', () {
    test('get', () => expect(router.resolve('/foo'), equals(getFoo)));

    test('post', () {
      router.dumpTree();
      expect(router.resolve('/foo', method: 'POST'), equals(postFoo));
    });
  });

  group('group', () {
    test('get', () {
      expect(router.resolve('/foo/bar'), equals(getFooBar));
    });

    test('post', () {
      expect(router.resolve('/foo/bar', method: 'POST'), equals(postFooBar));
    });

    test('patch+id', () {
      router.dumpTree();
      expect(
          router.resolve('/foo/bar/2', method: 'PATCH'), equals(patchFooBarId));
    });

    test('404', () {
      expect(router.resolve('/foo/bar/A', method: 'PATCH'), isNull);
    });
  });

  group('mount', () {
    group('no params', () {
      test('get', () {
        expect(router.resolve('/books'), equals(getBooks));
        expect(router.resolve('/books/foo'), equals(getBooksFoo));
      });

      test('post', () {
        expect(router.resolve('/books', method: 'POST'), equals(postBooks));
        expect(
            router.resolve('/books/foo', method: 'POST'), equals(postBooksFoo));
      });
    });

    group('with params', () {
      test('1 param', () {
        expect(router.resolve('/books/abc/chapters'), equals(getBooksChapters));
        expect(router.resolve('/books/abc/chapters', method: 'POST'),
            equals(postBooksChapters));
      });

      group('2 params', () {
        setUp(router.dumpTree);

        test('get', () {
          expect(router.resolve('/books/abc/chapters/ABC/reviews'),
              equals(getBooksChaptersReviews));
        });

        test('post', () {
          expect(
              router.resolve('/books/abc/chapters/ABC/reviews', method: 'POST'),
              equals(postBooksChaptersReviews));
        });

        test('404', () {
          expect(router.resolve('/books/abc/chapters/1'), isNull);
          expect(router.resolve('/books/abc/chapters/12'), isNull);
          expect(router.resolve('/books/abc/chapters/13.!'), isNull);
        });
      });
    });
  });

  test('flatten', () {
    router.dumpTree(header: 'BEFORE FLATTENING:');
    final flat = router.flatten();

    for (Route route in flat.root.children) {
      print('${route.method} ${route.path} => ${route.matcher.pattern}');
    }
  });
}
