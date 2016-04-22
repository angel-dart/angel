import 'package:angel_framework/angel_framework.dart';
import 'package:angel_configuration/angel_configuration.dart';
import 'package:test/test.dart';

main() {
  // Note: Set ANGEL_ENV to 'development'

  Angel angel = new Angel();

  test('can load based on ANGEL_ENV', () {
    angel.configure(loadConfigurationFile(directoryPath: './test/config'));
    expect(angel.properties['hello'], equals('world'));
    expect(angel.properties['foo']['version'], equals('bar'));
  });

  test('will load default.yaml if exists', () {
    expect(angel.properties["set_via"], equals("default"));
  });


  test('can override ANGEL_ENV', () {
    angel.configure(loadConfigurationFile(
        directoryPath: './test/config', overrideEnvironmentName: 'override'));
    expect(angel.properties['hello'], equals('goodbye'));
    expect(angel.properties['foo']['version'], equals('baz'));
  });
}