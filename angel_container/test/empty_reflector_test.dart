import 'package:angel_container/angel_container.dart';
import 'package:test/test.dart';

void main() {
  var reflector = const EmptyReflector();

  test('getName', () {
    expect(reflector.getName(#foo), 'foo');
    expect(reflector.getName(#==), '==');
  });

  group('reflectClass', () {
    var mirror = reflector.reflectClass(Truck);

    test('name returns empty', () {
      expect(mirror.name, '(empty)');
    });

    test('annotations returns empty', () {
      expect(mirror.annotations, isEmpty);
    });

    test('typeParameters returns empty', () {
      expect(mirror.typeParameters, isEmpty);
    });

    test('declarations returns empty', () {
      expect(mirror.declarations, isEmpty);
    });

    test('constructors returns empty', () {
      expect(mirror.constructors, isEmpty);
    });

    test('reflectedType returns Object', () {
      expect(mirror.reflectedType, Object);
    });

    test('cannot call newInstance', () {
      expect(() => mirror.newInstance('', []), throwsUnsupportedError);
    });

    test('isAssignableTo self', () {
      expect(mirror.isAssignableTo(mirror), true);
    });
  });

  group('reflectType', () {
    var mirror = reflector.reflectType(Truck);

    test('name returns empty', () {
      expect(mirror.name, '(empty)');
    });

    test('typeParameters returns empty', () {
      expect(mirror.typeParameters, isEmpty);
    });

    test('reflectedType returns Object', () {
      expect(mirror.reflectedType, Object);
    });

    test('cannot call newInstance', () {
      expect(() => mirror.newInstance('', []), throwsUnsupportedError);
    });

    test('isAssignableTo self', () {
      expect(mirror.isAssignableTo(mirror), true);
    });
  });

  group('reflectFunction', () {
    void doIt(int x) {}

    var mirror = reflector.reflectFunction(doIt);

    test('name returns empty', () {
      expect(mirror.name, '(empty)');
    });

    test('annotations returns empty', () {
      expect(mirror.annotations, isEmpty);
    });

    test('typeParameters returns empty', () {
      expect(mirror.typeParameters, isEmpty);
    });

    test('parameters returns empty', () {
      expect(mirror.parameters, isEmpty);
    });

    test('return type is dynamic', () {
      expect(mirror.returnType, reflector.reflectType(dynamic));
    });

    test('isGetter returns false', () {
      expect(mirror.isGetter, false);
    });

    test('isSetter returns false', () {
      expect(mirror.isSetter, false);
    });

    test('cannot invoke', () {
      var invocation = Invocation.method(#drive, []);
      expect(() => mirror.invoke(invocation), throwsUnsupportedError);
    });
  });

  group('reflectInstance', () {
    var mirror = reflector.reflectInstance(Truck());

    test('reflectee returns null', () {
      expect(mirror.reflectee, null);
    });

    test('type returns empty', () {
      expect(mirror.type.name, '(empty)');
    });

    test('clazz returns empty', () {
      expect(mirror.clazz.name, '(empty)');
    });

    test('cannot getField', () {
      expect(() => mirror.getField('wheelCount'), throwsUnsupportedError);
    });
  });
}

class Truck {
  int get wheelCount => 4;

  void drive() {
    print('Vroom!!!');
  }
}
