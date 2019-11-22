import 'dart:async';

import 'package:data_loader/data_loader.dart';
import 'package:test/test.dart';

void main() {
  var numbers = List.generate(10, (i) => i.toStringAsFixed(2));
  var numberLoader = DataLoader<int, String>((ids) {
    print('ID batch: $ids');
    return ids.map((i) => numbers[i]);
  });

  test('batch', () async {
    var zero = numberLoader.load(0);
    var one = numberLoader.load(1);
    var two = numberLoader.load(2);
    var batch = await Future.wait([zero, one, two]);
    print('Fetched result: $batch');
    expect(batch, ['0.00', '1.00', '2.00']);
  });

  test('dedupe', () async {
    var loader = DataLoader<int, Map<int, List<int>>>((ids) {
      return ids.map(
        (i) => {i: ids.toList()},
      );
    });

    var zero = loader.load(0);
    var one = loader.load(1);
    var two = loader.load(2);
    var anotherZero = loader.load(0);
    var batch = await Future.wait([zero, one, two, anotherZero]);

    expect(
      batch,
      [
        { 0: [0, 1, 2]},
        { 1: [0, 1, 2]},
        { 2: [0, 1, 2]},
        { 0: [0, 1, 2]},
      ],
    );
  });

  group('cache', () {
    DataLoader<int, _Unique> uniqueLoader, noCache;

    setUp(() {
      uniqueLoader = DataLoader<int, _Unique>((ids) async {
        var numbers = await numberLoader.loadMany(ids);
        return numbers.map((s) => _Unique(s));
      });
      noCache = DataLoader(uniqueLoader.loadMany, cache: false);
    });

    tearDown(() {
      uniqueLoader.close();
      noCache.close();
    });

    test('only lookup once', () async {
      var a = await uniqueLoader.load(3);
      var b = await uniqueLoader.load(3);
      expect(a, b);
    });

    test('can be disabled', () async {
      var a = await noCache.load(3);
      var b = await noCache.load(3);
      expect(a, isNot(b));
    });

    test('clear', () async {
      var a = await uniqueLoader.load(3);
      uniqueLoader.clear(3);
      var b = await uniqueLoader.load(3);
      expect(a, isNot(b));
    });

    test('clearAll', () async {
      var a = await uniqueLoader.load(3);
      uniqueLoader.clearAll();
      var b = await uniqueLoader.load(3);
      expect(a, isNot(b));
    });

    test('prime', () async {
      uniqueLoader.prime(3, _Unique('hey'));
      var a = await uniqueLoader.load(3);
      expect(a.value, 'hey');
    });
  });
}

class _Unique {
  final String value;

  _Unique(this.value);
}
