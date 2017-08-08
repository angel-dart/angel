import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:code_builder/dart/core.dart';
import 'package:code_builder/code_builder.dart';
import 'package:console/console.dart';
import 'package:pubspec/pubspec.dart';
import 'package:recase/recase.dart';
import 'maker.dart';

class ControllerCommand extends Command {
  final TextPen _pen = new TextPen();

  @override
  String get name => 'controller';

  @override
  String get description => 'Generates a controller class.';

  ControllerCommand() {
    argParser
      ..addFlag('websocket',
          abbr: 'w',
          help:
              'Generates a WebSocketController, instead of an HTTP controller.',
          negatable: false)
      ..addOption('name',
          abbr: 'n', help: 'Specifies a name for the model class.')
      ..addOption('output-dir',
          help: 'Specifies a directory to create the controller class in.',
          defaultsTo: 'lib/src/controllers');
  }

  @override
  run() async {
    var pubspec = await PubSpec.load(Directory.current);
    String name;
    if (argResults.wasParsed('name')) name = argResults['name'];

    if (name?.isNotEmpty != true) {
      var p = new Prompter('Name of Controller class: ');
      name = await p.prompt(checker: (s) => s.isNotEmpty);
    }

    List<MakerDependency> deps = [
      const MakerDependency('angel_framework', '^1.0.0')
    ];

    var rc = new ReCase(name);
    var controllerLib =
        new LibraryBuilder('${pubspec.name}.src.controllers.${rc.snakeCase}');

    if (argResults['websocket']) {
      deps.add(const MakerDependency('angel_websocket', '^1.0.0'));
      controllerLib.addDirective(
          new ImportBuilder('package:angel_websocket/server.dart'));
    } else
      controllerLib.addDirective(
          new ImportBuilder('package:angel_framework/angel_framework.dart'));

    TypeBuilder parentType = new TypeBuilder(
        argResults['websocket'] ? 'WebSocketController' : 'Controller');
    ClassBuilder clazz =
        new ClassBuilder('${rc.pascalCase}Controller', asExtends: parentType);
    controllerLib.addMember(clazz);

    if (argResults['websocket']) {
      var meth = new MethodBuilder('hello', returnType: lib$core.$void);
      meth.addAnnotation(new TypeBuilder('ExposeWs')
          .constInstance([literal('get_${rc.snakeCase}')]));
      meth.addPositional(
          parameter('socket', [new TypeBuilder('WebSocketContext')]));
      meth.addStatement(reference('socket').invoke('send', [
        literal('got_${rc.snakeCase}'),
        map({'message': literal('Hello, world!')})
      ]));
      clazz.addMethod(meth);
    } else {
      clazz.addAnnotation(new TypeBuilder('Expose')
          .constInstance([literal('/${rc.snakeCase}')]));

      var meth = new MethodBuilder('hello',
          returnType: lib$core.String, returns: literal('Hello, world!'));
      meth.addAnnotation(
          new TypeBuilder('Expose').constInstance([literal('/')]));
      clazz.addMethod(meth);
    }

    var outputDir = new Directory.fromUri(
        Directory.current.uri.resolve(argResults['output-dir']));
    var controllerFile =
        new File.fromUri(outputDir.uri.resolve('${rc.snakeCase}.dart'));
    if (!await controllerFile.exists())
      await controllerFile.create(recursive: true);
    await controllerFile
        .writeAsString(prettyToSource(controllerLib.buildAst()));
    _pen
      ..green()
      ..call(
          '${Icon.CHECKMARK} Created controller file "${controllerFile.absolute.path}".')
      ..call()
      ..reset();

    if (deps.isNotEmpty) await depend(deps);
  }
}
