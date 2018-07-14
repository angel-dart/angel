import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:console/console.dart';
import 'package:inflection/inflection.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:recase/recase.dart';
import '../service_generators/service_generators.dart';
import 'maker.dart';

class ServiceCommand extends Command {
  final TextPen _pen = new TextPen();

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
    var pubspec = await Pubspec.load(Directory.current);
    String name;
    if (argResults.wasParsed('name')) name = argResults['name'];

    if (name?.isNotEmpty != true) {
      var p = new Prompter('Name of Service: ');
      name = await p.prompt(checker: (s) => s.isNotEmpty);
    }

    List<MakerDependency> deps = [
      const MakerDependency('angel_framework', '^1.0.0')
    ];

    var rc = new ReCase(name);
    var serviceLib =
        new LibraryBuilder('${pubspec.name}.src.services.${rc.snakeCase}');

    ServiceGenerator generator;

    var chooser = new Chooser<String>(
        serviceGenerators.map<String>((g) => g.name).toList(),
        message: 'What type of service would you like to create? ');
    var type = await chooser.choose();

    generator =
        serviceGenerators.firstWhere((g) => g.name == type, orElse: () => null);

    if (generator == null) {
      _pen.red();
      _pen('${Icon.BALLOT_X} \'$type\' services are not yet implemented. :(');
      _pen();
      throw 'Unrecognized service type: "$type".';
    }

    for (var dep in generator.dependencies) {
      if (!deps.any((d) => d.name == dep.name)) deps.add(dep);
    }

    if (generator.goesFirst) {
      generator.applyToLibrary(serviceLib, name, rc.snakeCase);
      serviceLib.addMember(
          new ImportBuilder('package:angel_framework/angel_framework.dart'));
    } else {
      serviceLib.addMember(
          new ImportBuilder('package:angel_framework/angel_framework.dart'));
      generator.applyToLibrary(serviceLib, name, rc.snakeCase);
    }

    if (argResults['typed']) {
      serviceLib
        ..addMember(new ImportBuilder('../models/${rc.snakeCase}.dart'));
    }

    // configureServer() {}
    var configureServer = new MethodBuilder('configureServer',
        returnType: new TypeBuilder('AngelConfigurer'));
    generator.applyToConfigureServer(configureServer, name, rc.snakeCase);

    // return (Angel app) async {}
    var closure = new MethodBuilder.closure(modifier: MethodModifier.asAsync)
      ..addPositional(parameter('app', [new TypeBuilder('Angel')]));
    generator.beforeService(closure, name, rc.snakeCase);

    // app.use('/api/todos', new MapService());
    var service = generator.createInstance(closure, name, rc.snakeCase);

    if (argResults['typed']) {
      service = new TypeBuilder('TypedService',
              genericTypes: [new TypeBuilder(rc.pascalCase)])
          .newInstance([service]);
    }

    closure.addStatement(reference('app')
        .invoke('use', [literal('/api/${pluralize(rc.snakeCase)}'), service]));
    configureServer.addStatement(closure.asReturn());
    serviceLib.addMember(configureServer);

    final outputDir = new Directory.fromUri(
        Directory.current.uri.resolve(argResults['output-dir']));
    final serviceFile =
        new File.fromUri(outputDir.uri.resolve("${rc.snakeCase}.dart"));
    if (!await serviceFile.exists()) await serviceFile.create(recursive: true);
    await serviceFile.writeAsString(prettyToSource(serviceLib.buildAst()));

    _pen.green();
    _pen(
        '${Icon.CHECKMARK} Successfully generated service file "${serviceFile.absolute.path}".');
    _pen();

    if (deps.isNotEmpty) await depend(deps);
  }
}
