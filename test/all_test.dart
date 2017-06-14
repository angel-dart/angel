import 'package:angel_framework/angel_framework.dart';
import 'package:angel_configuration/angel_configuration.dart';
import 'package:test/test.dart';
import 'transformer.dart' as transformer;

main() async {
  // Note: Set ANGEL_ENV to 'development'
  var app = new Angel();
  await app.configure(
      loadConfigurationFile(directoryPath: './test/config'));

  test('can load based on ANGEL_ENV', () async {
    expect(app.properties['hello'], equals('world'));
    expect(app.properties['foo']['version'], equals('bar'));
  });

  test('will load default.yaml if exists', () {
    expect(app.properties["set_via"], equals("default"));
  });

  test('will load .env if exists', () {
    expect(app.properties['artist'], 'Timberlake');
    expect(app.properties['angel'], {'framework': 'cool'});
  });

  test('non-existent environment defaults to null', () {
    expect(app.properties.keys, contains('must_be_null'));
    expect(app.properties['must_be_null'], null);
  });

  test('can override ANGEL_ENV', () async {
    await app.configure(loadConfigurationFile(
        directoryPath: './test/config', overrideEnvironmentName: 'override'));
    expect(app.properties['hello'], equals('goodbye'));
    expect(app.properties['foo']['version'], equals('baz'));
  });



  group("transformer", transformer.main);
}
