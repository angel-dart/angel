import 'dart:io';
import 'package:args/command_runner.dart';
import "package:console/console.dart";
import 'package:dart_style/dart_style.dart';
import 'package:pubspec/pubspec.dart';
import 'package:recase/recase.dart';
import 'maker.dart';

class TestCommand extends Command {
  final TextPen _pen = new TextPen();

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
    var pubspec = await PubSpec.load(Directory.current);
    String name;
    if (argResults.wasParsed('name')) name = argResults['name'];

    if (name?.isNotEmpty != true) {
      var p = new Prompter('Name of Test: ');
      name = await p.prompt(checker: (s) => s.isNotEmpty);
    }

    List<MakerDependency> deps = [
      const MakerDependency('angel_framework', '^1.0.0'),
      const MakerDependency('angel_test', '^1.0.0', dev: true),
      const MakerDependency('test', '^0.12.0', dev: true),
    ];

    var rc = new ReCase(name);
    final testDir = new Directory.fromUri(
        Directory.current.uri.resolve(argResults['output-dir']));
    final testFile =
        new File.fromUri(testDir.uri.resolve("${rc.snakeCase}_test.dart"));
    if (!await testFile.exists()) await testFile.create(recursive: true);
    await testFile
        .writeAsString(new DartFormatter().format(_generateTest(pubspec, rc)));

    if (deps.isNotEmpty) await depend(deps);

    _pen.green();
    _pen(
        '${Icon.CHECKMARK} Successfully generated test file "${testFile.absolute.path}".');
    _pen();

    if (argResults['run-configuration']) {
      final runConfig = new File.fromUri(Directory.current.uri
          .resolve('.idea/runConfigurations/${name}_Tests.xml'));

      if (!await runConfig.exists()) await runConfig.create(recursive: true);
      await runConfig.writeAsString(_generateRunConfiguration(name, rc));

      _pen.reset();
      _pen.green();
      _pen(
          '${Icon.CHECKMARK} Successfully generated run configuration "$name Tests" at "${runConfig.absolute.path}".');
      _pen();
    }
  }

  _generateRunConfiguration(String name, ReCase rc) {
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

  String _generateTest(PubSpec pubspec, ReCase rc) {
    return '''
import 'dart:io';
import 'package:${pubspec.name}/${pubspec.name}.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

main() async {
  TestClient client;

  setUp(() async {
    var app = await createServer();
    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('${rc.snakeCase}', () async {
    final response = await client.get('/${rc.snakeCase}');
    expect(response, hasStatus(HttpStatus.OK));
  });
}
    ''';
  }
}
