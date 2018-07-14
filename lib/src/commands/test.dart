import 'dart:io';
import 'package:args/command_runner.dart';
import "package:console/console.dart";
import 'package:dart_style/dart_style.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:recase/recase.dart';
import 'deprecated.dart';

class TestCommand extends Command {
  final TextPen _pen = new TextPen();

  @override
  String get name => "test";

  @override
  String get description => "Creates a new test within the given project.";

  @override
  run() async {
    warnDeprecated(this.name, _pen);

    final name = await readInput("Name of Test: "),
        lower = new ReCase(name).snakeCase;
    final testDir = new Directory("test/services");
    final testFile =
        new File.fromUri(testDir.uri.resolve("${lower}_test.dart"));

    if (!await testFile.exists()) await testFile.create(recursive: true);

    await testFile.writeAsString(new DartFormatter()
        .format(_generateTest(await Pubspec.load(Directory.current), lower)));

    final runConfig = new File('./.idea/runConfigurations/${name}_tests.xml');

    if (!await runConfig.exists()) {
      await runConfig.create(recursive: true);
      await runConfig.writeAsString(_generateRunConfiguration(name));
    }

    _pen.green();
    _pen("${Icon.CHECKMARK} Successfully generated test $name.");
    _pen();
  }

  _generateRunConfiguration(String name) {
    final lower = name.toLowerCase();

    return '''
    <component name="ProjectRunConfigurationManager">
      <configuration default="false" name="$name Tests" type="DartTestRunConfigurationType" factoryName="Dart Test" singleton="true">
        <option name="filePath" value="\$PROJECT_DIR\$/test/${lower}_test.dart" />
        <method />
      </configuration>
    </component>
'''
        .trim();
  }

  String _generateTest(Pubspec pubspec, String lower) {
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

  test('$lower', () async {
    final response = await client.get('/$lower');
    expect(response, hasStatus(HttpStatus.OK));
  });
}
    '''
        .trim();
  }
}
