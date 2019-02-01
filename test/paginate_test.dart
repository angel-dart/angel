import 'package:angel_paginate/angel_paginate.dart';
import 'package:test/test.dart';

// Count-down from 100, then 101 at the end...
final List<int> DATA = new List<int>.generate(100, (i) => 100 - i)..add(101);

main() {
  group('cache', () {
    var cached = new Paginator<int>(DATA),
        uncached = new Paginator<int>(DATA, useCache: false);

    test('always cache current', () {
      expect(cached.current, cached.current);
      expect(uncached.current, uncached.current);
    });

    test('only cache prev/next if useCache != false', () {
      var cached1 = cached.current;
      cached.goToPage(4);
      var cached4 = cached.current;
      cached.goToPage(1);
      expect(cached.current, cached1);
      cached.goToPage(4);
      expect(cached.current, cached4);

      var uncached1 = uncached.current;
      uncached.goToPage(4);
      var uncached4 = uncached.current;
      uncached.goToPage(1);
      expect(uncached.current, isNot(uncached1));
      uncached.goToPage(4);
      expect(uncached.current, isNot(uncached4));
    });
  });

  test('default state', () {
    var paginator = new Paginator<int>(DATA);
    expect(paginator.index, 0);
    expect(paginator.pageNumber, 1);
    expect(paginator.itemsPerPage, 5);
    expect(paginator.useCache, true);
    expect(paginator.canGoBack, false);
    expect(paginator.canGoForward, true);
    expect(paginator.lastPageNumber, 21);

    // Going back should do nothing
    var p = paginator.pageNumber;
    paginator.back();
    expect(paginator.pageNumber, p);
  });

  group('paginate', () {
    test('first page', () {
      var paginator = new Paginator<int>(DATA);
      expect(paginator.pageNumber, 1);
      var r = paginator.current;
      print(r.toJson());
      expect(r.total, DATA.length);
      expect(r.itemsPerPage, 5);
      expect(r.previousPage, -1);
      expect(r.currentPage, 1);
      expect(r.nextPage, 2);
      expect(r.startIndex, 0);
      expect(r.endIndex, 4);
      expect(r.data, DATA.skip(r.startIndex).take(r.itemsPerPage).toList());
    });
  });

  test('third page', () {
    var paginator = new Paginator<int>(DATA)..goToPage(3);
    expect(paginator.pageNumber, 3);
    var r = paginator.current;
    print(r.toJson());
    expect(r.total, DATA.length);
    expect(r.itemsPerPage, 5);
    expect(r.previousPage, 2);
    expect(r.currentPage, 3);
    expect(r.nextPage, 4);
    expect(r.startIndex, 10);
    expect(r.endIndex, 14);
    expect(r.data, DATA.skip(r.startIndex).take(r.itemsPerPage).toList());

    paginator.back();
    expect(paginator.pageNumber, 2);
  });

  test('last page', () {
    var paginator = new Paginator<int>(DATA);
    paginator.goToPage(paginator.lastPageNumber);
    var r = paginator.current;
    expect(r.total, DATA.length);
    expect(r.itemsPerPage, 5);
    expect(r.previousPage, paginator.lastPageNumber - 1);
    expect(r.currentPage, paginator.lastPageNumber);
    expect(r.nextPage, -1);
    expect(r.startIndex, (paginator.lastPageNumber - 1) * 5);
    expect(r.endIndex, r.startIndex);
    expect(r.data, [DATA.last]);
    expect(r.data, DATA.skip(r.startIndex).take(r.itemsPerPage).toList());
  });

  test('dump pages', () {
    var paginator = new Paginator<int>(DATA);
    print('${paginator.lastPageNumber} page(s) of data:');

    do {
      print('  * Page #${paginator.pageNumber}: ${paginator.current.data}');
      paginator.next();
    } while (paginator.canGoForward);
  });

  test('empty collection', () {
    var paginator = new Paginator([]);
    var page = paginator.current;
    print(page.toJson());

    expect(page.total, 0);
    expect(page.previousPage, -1);
    expect(page.nextPage, -1);
    expect(page.currentPage, 1);
    expect(page.startIndex, -1);
    expect(page.endIndex, -1);
    expect(page.data, isEmpty);
    expect(paginator.canGoBack, isFalse);
    expect(paginator.canGoForward, isFalse);
  });
}
