import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:dart_style/dart_style.dart';
import 'package:io/ansi.dart';
import 'package:prompts/prompts.dart' as prompter;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:recase/recase.dart';
import '../../util.dart';
import 'maker.dart';

class TestCommand extends Command {
  @override
  String get name => "test";

  @override
  String get description => "Creates a new test within the given project.";

  TestCommand() {
    argParser
      ..addFlag('run-configuration',
          help: 'Generate a run configuration for JetBrains IDE\'s.',
          defaultsTo: true)
      ..addOption('name',
          abbr: 'n', help: 'Specifies a name for the plug-in class.')
      ..addOption('output-dir',
          help: 'Specifies a directory to create the plug-in class in.',
          defaultsTo: 'test');
  }

  @override
  run() async {
    var pubspec = await loadPubspec();
    String name;
    if (argResults.wasParsed('name')) name = argResults['name'] as String;

    if (name?.isNotEmpty != true) {
      name = prompter.get('Name of test');
    }

    List<MakerDependency> deps = [
      const MakerDependency('angel_framework', '^2.0.0'),
      const MakerDependency('angel_test', '^2.0.0', dev: true),
      const MakerDependency('test', '^1.0.0', dev: true),
    ];

    var rc = new ReCase(name);
    final testDir = new Directory.fromUri(
        Directory.current.uri.resolve(argResults['output-dir'] as String));
    final testFile =
        new File.fromUri(testDir.uri.resolve("${rc.snakeCase}_test.dart"));
    if (!await testFile.exists()) await testFile.create(recursive: true);
    await testFile
        .writeAsString(new DartFormatter().format(_generateTest(pubspec, rc)));

    if (deps.isNotEmpty) await depend(deps);

    print(green.wrap(
        '$checkmark Successfully generated test file "${testFile.absolute.path}".'));

    if (argResults['run-configuration'] as bool) {
      final runConfig = new File.fromUri(Directory.current.uri
          .resolve('.idea/runConfigurations/${name}_Tests.xml'));

      if (!await runConfig.exists()) await runConfig.create(recursive: true);
      await runConfig.writeAsString(_generateRunConfiguration(name, rc));

      print(green.wrap(
          '$checkmark Successfully generated run configuration "$name Tests" at "${runConfig.absolute.path}".'));
    }
  }

  String _generateRunConfiguration(String name, ReCase rc) {
    return '''
    <component name="ProjectRunConfigurationManager">
      <configuration default="false" name="$name Tests" type="DartTestRunConfigurationType" factoryName="Dart Test" singleton="true">
        <option name="filePath" value="\$PROJECT_DIR\$/test/${rc.snakeCase}_test.dart" />
        <method />
      </configuration>
    </component>
'''
        .trim();
  }

  String _generateTest(Pubspec pubspec, ReCase rc) {
    return '''
import 'dart:io';
import 'package:${pubspec.name}/${pubspec.name}.dart' as ${pubspec.name};
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

main() async {
  TestClient client;

  setUp(() async {
    var app = new Angel();
    await app.configure(${pubspec.name}.configureServer);
    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('${rc.snakeCase}', () async {
    final response = await client.get('/${rc.snakeCase}');
    expect(response, hasStatus(HttpStatus.ok));
  });
}
    ''';
  }
}
