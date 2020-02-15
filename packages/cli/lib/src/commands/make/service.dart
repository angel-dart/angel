import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:inflection2/inflection2.dart';
import 'package:io/ansi.dart';
import 'package:prompts/prompts.dart' as prompts;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:recase/recase.dart';
import '../service_generators/service_generators.dart';
import '../../util.dart';
import 'maker.dart';

class ServiceCommand extends Command {
  @override
  String get name => 'service';

  @override
  String get description => 'Generates an Angel service.';

  ServiceCommand() {
    argParser
      ..addFlag('typed',
          abbr: 't',
          help: 'Wrap the generated service in a `TypedService` instance.',
          negatable: false)
      ..addOption('name',
          abbr: 'n', help: 'Specifies a name for the service file.')
      ..addOption('output-dir',
          help: 'Specifies a directory to create the service file.',
          defaultsTo: 'lib/src/services');
  }

  @override
  run() async {
    var pubspec = await loadPubspec();
    String name;
    if (argResults.wasParsed('name')) name = argResults['name'] as String;

    if (name?.isNotEmpty != true) {
      name = prompts.get('Name of service');
    }

    List<MakerDependency> deps = [
      const MakerDependency('angel_framework', '^2.0.0')
    ];

    // '${pubspec.name}.src.services.${rc.snakeCase}'
    var rc = new ReCase(name);
    var serviceLib = new Library((serviceLib) {
      var generator = prompts.choose(
          'Choose which type of service to create', serviceGenerators);

//      if (generator == null) {
//        _pen.red();
//        _pen('${Icon.BALLOT_X} \'$type\' services are not yet implemented. :(');
//        _pen();
//        throw 'Unrecognized service type: "$type".';
//      }

      for (var dep in generator.dependencies) {
        if (!deps.any((d) => d.name == dep.name)) deps.add(dep);
      }

      if (generator.goesFirst) {
        generator.applyToLibrary(serviceLib, name, rc.snakeCase);
        serviceLib.directives.add(new Directive.import(
            'package:angel_framework/angel_framework.dart'));
      } else {
        serviceLib.directives.add(new Directive.import(
            'package:angel_framework/angel_framework.dart'));
        generator.applyToLibrary(serviceLib, name, rc.snakeCase);
      }

      if (argResults['typed'] as bool) {
        serviceLib.directives
            .add(new Directive.import('../models/${rc.snakeCase}.dart'));
      }

      // configureServer() {}
      serviceLib.body.add(new Method((configureServer) {
        configureServer
          ..name = 'configureServer'
          ..returns = refer('AngelConfigurer');

        configureServer.body = new Block((block) {
          generator.applyToConfigureServer(
              serviceLib, configureServer, block, name, rc.snakeCase);

          // return (Angel app) async {}
          var closure = new Method((closure) {
            closure
              ..modifier = MethodModifier.async
              ..requiredParameters.add(new Parameter((b) => b
                ..name = 'app'
                ..type = refer('Angel')));
            closure.body = new Block((block) {
              generator.beforeService(serviceLib, block, name, rc.snakeCase);

              // app.use('/api/todos', new MapService());
              var service = generator.createInstance(
                  serviceLib, closure, name, rc.snakeCase);

              if (argResults['typed'] as bool) {
                var tb = new TypeReference((b) => b
                  ..symbol = 'TypedService'
                  ..types.add(refer(rc.pascalCase)));
                service = tb.newInstance([service]);
              }

              block.addExpression(refer('app').property('use').call([
                literal('/api/${pluralize(rc.snakeCase)}'),
                service,
              ]));
            });
          });

          block.addExpression(closure.closure.returned);
        });
      }));
    });

    final outputDir = new Directory.fromUri(
        Directory.current.uri.resolve(argResults['output-dir'] as String));
    final serviceFile =
        new File.fromUri(outputDir.uri.resolve("${rc.snakeCase}.dart"));
    if (!await serviceFile.exists()) await serviceFile.create(recursive: true);
    await serviceFile.writeAsString(new DartFormatter()
        .format(serviceLib.accept(new DartEmitter()).toString()));

    print(green.wrap(
        '$checkmark Successfully generated service file "${serviceFile.absolute.path}".'));

    if (deps.isNotEmpty) await depend(deps);
  }
}
