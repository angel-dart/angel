import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:console/console.dart';
import 'package:inflection/inflection.dart';
import 'package:pubspec/pubspec.dart';
import 'package:recase/recase.dart';
import 'service_generators/service_generators.dart';
import 'init.dart' show preBuild;

const List<ServiceGenerator> GENERATORS = const [
  const MapServiceGenerator(),
  const MongoServiceGenerator(),
  const RethinkServiceGenerator(),
  const CustomServiceGenerator()
];

class ServiceCommand extends Command {
  final TextPen _pen = new TextPen();

  @override
  String get name => 'service';

  @override
  String get description => 'Creates a new service within the given project.';

  @override
  run() async {
    var pubspec = await PubSpec.load(Directory.current);
    var name = await readInput('Name of Service (not plural): ');
    var chooser = new Chooser<String>(
        GENERATORS.map<String>((g) => g.name).toList(),
        message: 'What type of service would you like to create? ');
    var type = await chooser.choose();

    print('Wrap this service in a TypedService? (slight performance cost)');
    chooser = new Chooser<String>(['Yes', 'No']);
    var typed = (await chooser.choose()) == 'Yes';

    var generator =
        GENERATORS.firstWhere((g) => g.name == type, orElse: () => null);

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

      await serviceFile
          .writeAsString(_generateService(generator, name, lower, typed));
      await testFile.writeAsString(_generateTests(pubspec, lower));

      var runConfig = new File('./.idea/runConfigurations/${name}_Tests.xml');

      if (!await runConfig.exists()) {
        await runConfig.create(recursive: true);
        await runConfig.writeAsString(_generateRunConfiguration(name, lower));
      }

      if (generator.createsModel == true) {
        await _generateModel(name, lower);
      }

      if (generator.createsValidator == true) {
        await _generateValidator(lower, rc.constantCase);
      }

      if (generator.exportedInServiceLibrary == true) {
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
    lib.addMember(
        new ImportBuilder('package:angel_common/angel_common.dart'));
    generator.applyToLibrary(lib, name, lower);

    if (generator.createsModel == true) {
      lib
        ..addMember(new ImportBuilder('../models/$lower.dart'))
        ..addMember(new ExportBuilder('../models/$lower.dart'));
    }

    // configureServer() {}
    var configureServer = new MethodBuilder('configureServer',
        returnType: new TypeBuilder('AngelConfigurer'));
    generator.applyToConfigureServer(configureServer, name, lower);

    // return (Angel app) async {}
    var closure = new MethodBuilder.closure(modifier: MethodModifier.asAsync)
      ..addPositional(parameter('app', [new TypeBuilder('Angel')]));
    generator.beforeService(closure, name, lower);

    // app.use('/api/todos', new MapService());
    var service = generator.createInstance(closure, name, lower);

    if (typed == true) {
      service =
          new TypeBuilder('TypedService', genericTypes: [new TypeBuilder(name)])
              .newInstance([service]);
    }

    closure.addStatement(reference('app')
        .invoke('use', [literal('/api/${pluralize(lower)}'), service]));

    if (generator.injectsSingleton == true) {
      closure.addStatement(varField('service',
          value: reference('app')
              .invoke('service', [literal('/api/${pluralize(lower)}')]).castAs(
                  new TypeBuilder('HookedService'))));
      closure.addStatement(reference('app')
          .property('container')
          .invoke('singleton', [reference('service').property('inner')]));
    }

    configureServer.addStatement(closure.asReturn());

    lib.addMember(configureServer);

    return prettyToSource(lib.buildAst());
  }

  _generateModel(String name, String lower) async {
    var file = new File('lib/src/models/$lower.dart');

    if (!await file.exists()) await file.createSync(recursive: true);

    await file.writeAsString('''

import 'package:angel_framework/common.dart';

class $name extends Model {
  String name;
  
  String desc;

  $name({String id, this.name, this.desc}) {
    this.id = id;
  }
}
    '''
        .trim());
  }

  _generateValidator(String lower, String constantCase) async {
    var file = new File('lib/src/validators/$lower.dart');

    if (!await file.exists()) await file.createSync(recursive: true);

    await file.writeAsString('''
import 'package:angel_validate/angel_validate.dart';

final Validator $constantCase = new Validator({
  'name': [isString, isNotEmpty],
  'desc': [isString, isNotEmpty]
});

final Validator CREATE_$constantCase = $constantCase.extend({})
  ..requiredFields.addAll(['name', 'desc']);

    '''
        .trim());
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

  _generateTests(PubSpec pubspec, String lower) {
    return '''
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

    '''
        .trim();
  }
}
