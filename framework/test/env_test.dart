import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:test/test.dart';

void main() {
  test('custom value', () => expect(AngelEnvironment('hey').value, 'hey'));

  test('lowercases', () => expect(AngelEnvironment('HeY').value, 'hey'));
  test(
      'default to env or development',
      () => expect(AngelEnvironment().value,
          (Platform.environment['ANGEL_ENV'] ?? 'development').toLowerCase()));
  test('isDevelopment',
      () => expect(AngelEnvironment('development').isDevelopment, true));
  test('isStaging', () => expect(AngelEnvironment('staging').isStaging, true));
  test('isDevelopment',
      () => expect(AngelEnvironment('production').isProduction, true));
}
