import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:console/console.dart';
import 'package:dart_style/dart_style.dart';
import 'package:inflection/inflection.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:recase/recase.dart';
import 'service_generators/service_generators.dart';
import 'deprecated.dart';
import 'init.dart' show preBuild;

class ServiceCommand extends Command {
  final TextPen _pen = new TextPen();

  @override
  String get name => 'service';

  @override
  String get description => 'Creates a new service within the given project.';

  @override
  run() async {
    warnDeprecated(this.name, _pen);
    
    var pubspec = await Pubspec.load(Directory.current);
    var name = await readInput('Name of Service (not plural): ');
    var chooser = new Chooser<String>(
        serviceGenerators.map<String>((g) => g.name).toList(),
        message: 'What type of service would you like to create? ');
    var type = await chooser.choose();

    print('Wrap this service in a TypedService? (slight performance cost)');
    chooser = new Chooser<String>(['Yes', 'No']);
    var typed = (await chooser.choose()) == 'Yes';

    var generator =
        serviceGenerators.firstWhere((g) => g.name == type, orElse: () => null);

    if (generator == null) {
      _pen.blue();
      _pen('${Icon.STAR} \'$type\' services are not yet implemented. :(');
      _pen();
    } else {
      var rc = new ReCase(name);
      name = rc.pascalCase;
      var lower = rc.snakeCase;
      var servicesDir = new Directory('lib/src/services');
      var serviceFile =
          new File.fromUri(servicesDir.uri.resolve('$lower.dart'));
      var testDir = new Directory('test/services');
      var testFile =
          new File.fromUri(testDir.uri.resolve('${lower}_test.dart'));

      if (!await servicesDir.exists())
        await servicesDir.create(recursive: true);
      if (!await testDir.exists()) await testDir.create(recursive: true);

      var fmt = new DartFormatter();

      await serviceFile
          .writeAsString(_generateService(generator, name, lower, typed));
      await testFile.writeAsString(_generateTests(pubspec, lower, fmt));

      var runConfig = new File('./.idea/runConfigurations/${name}_Tests.xml');

      if (!await runConfig.exists()) {
        await runConfig.create(recursive: true);
        await runConfig.writeAsString(_generateRunConfiguration(name, lower));
      }

      if (generator.createsModel == true || typed == true) {
        await _generateModel(pubspec, name, lower, fmt);
      }

      if (generator.createsValidator == true) {
        await _generateValidator(pubspec, lower, rc, fmt);
      }

      if (generator.exportedInServiceLibrary == true || typed == true) {
        var serviceLibrary = new File('lib/src/models/models.dart');
        await serviceLibrary.writeAsString("\nexport '$lower.dart';",
            mode: FileMode.APPEND);
      }

      if (generator.shouldRunBuild == true) {
        await preBuild(Directory.current);
      }

      _pen.green();
      _pen('${Icon.CHECKMARK} Successfully generated service $name.');
      _pen();
    }
  }

  String _generateService(
      ServiceGenerator generator, String name, String lower, bool typed) {
    var lib = new LibraryBuilder();

    /*
    import 'package:angel_framework/angel_framework.dart';
    import '../models/$lower.dart';
    export '../models/$lower.dart';
    */
    lib.addMember(new Directive.import('package:angel_common/angel_common.dart'));
    generator.applyToLibrary(lib, name, lower);

    if (generator.createsModel == true || typed) {
      lib
        ..addMember(new Directive.import('../models/$lower.dart'))
        ..addMember(new ExportBuilder('../models/$lower.dart'));
    }

    // configureServer() {}
    var configureServer = new MethodBuilder('configureServer',
        returnType: refer('AngelConfigurer'));
    generator.applyToConfigureServer(configureServer, name, lower);

    // return (Angel app) async {}
    var closure = new MethodBuilder.closure(modifier: MethodModifier.asAsync)
      ..addPositional(parameter('app', [refer('Angel')]));
    generator.beforeService(closure, name, lower);

    // app.use('/api/todos', new MapService());
    var service = generator.createInstance(closure, name, lower);

    if (typed == true) {
      service =
          refer('TypedService', genericTypes: [refer(name)])
              .newInstance([service]);
    }

    closure.addStatement(refer('app')
        .invoke('use', [literal('/api/${pluralize(lower)}'), service]));

    if (generator.injectsSingleton == true) {
      closure.addStatement(varField('service',
          value: refer('app')
              .invoke('service', [literal('/api/${pluralize(lower)}')]).castAs(
                  refer('HookedService'))));
      closure.addStatement(refer('app')
          .property('container')
          .invoke('singleton', [refer('service').property('inner')]));
    }

    configureServer.addStatement(closure.asReturn());

    lib.addMember(configureServer);

    return prettyToSource(lib.buildAst());
  }

  _generateModel(
      Pubspec pubspec, String name, String lower, DartFormatter fmt) async {
    var file = new File('lib/src/models/$lower.dart');

    if (!await file.exists()) await file.createSync(recursive: true);

    await file.writeAsString(fmt.format('''
library ${pubspec.name}.models.$lower;
import 'package:angel_model/angel_model.dart';

class $name extends Model {
  @override
  String id;
  String name, description;
  @override
  DateTime createdAt, updatedAt;

  $name({this.id, this.name, this.description, this.createdAt, this.updatedAt});
}
    '''));
  }

  _generateValidator(
      Pubspec pubspec, String lower, ReCase rc, DartFormatter fmt) async {
    var file = new File('lib/src/validators/$lower.dart');

    if (!await file.exists()) await file.createSync(recursive: true);

    await file.writeAsString(fmt.format('''
library ${pubspec.name}.validtors.$lower;
import 'package:angel_validate/angel_validate.dart';

final Validator ${rc.camelCase} = new Validator({
  'name': [isString, isNotEmpty],
  'description': [isString, isNotEmpty]
});

final Validator create${rc.pascalCase} = ${rc.camelCase}.extend({})
  ..requiredFields.addAll(['name', 'description']);
    '''));
  }

  _generateRunConfiguration(String name, String lower) {
    return '''
    <component name="ProjectRunConfigurationManager">
      <configuration default="false" name="$name Tests" type="DartTestRunConfigurationType" factoryName="Dart Test" singleton="true">
        <option name="filePath" value="\$PROJECT_DIR\$/test/services/${lower}_test.dart" />
        <method />
      </configuration>
    </component>
'''
        .trim();
  }

  _generateTests(Pubspec pubspec, String lower, DartFormatter fmt) {
    return fmt.format('''
import 'dart:io';
import 'package:${pubspec.name}/${pubspec.name}.dart';
import 'package:angel_common/angel_common.dart';
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

main() async {
  Angel app;
  TestClient client;

  setUp(() async {
    app = await createServer();
    client = await connectTo(app);
  });

  tearDown(() async {
    await client.close();
    app = null;
  });

  test('index via REST', () async {
    var response = await client.get('/api/${pluralize(lower)}');
    expect(response, hasStatus(HttpStatus.OK));
  });

  test('Index ${pluralize(lower)}', () async {
    var ${pluralize(lower)} = await client.service('api/${pluralize(lower)}').index();
    print(${pluralize(lower)});
  });
}

    ''');
  }
}
