import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import "package:console/console.dart";
import 'package:pubspec/pubspec.dart';
import 'package:recase/recase.dart';
import 'deprecated.dart';

class ControllerCommand extends Command {
  final TextPen _pen = new TextPen();

  @override
  String get name => "controller";

  @override
  String get description =>
      "Creates a new controller within the given project.";

  @override
  run() async {
    warnDeprecated(this.name, _pen);

    final name = await readInput("Name of Controller: "),
        recase = new ReCase(name),
        lower = recase.snakeCase;
    final controllersDir = new Directory("lib/src/routes/controllers");
    final controllerFile =
        new File.fromUri(controllersDir.uri.resolve("$lower.dart"));

    if (!await controllerFile.exists())
      await controllerFile.create(recursive: true);

    await controllerFile.writeAsString(
        _generateController(await PubSpec.load(Directory.current), recase));

    _pen.green();
    _pen("${Icon.CHECKMARK} Successfully generated controller $name.");
    _pen();
  }

  NewInstanceBuilder _expose(String path) => new TypeBuilder('Expose')
      .constInstance([], namedArguments: {'path': literal(path)});

  String _generateController(PubSpec pubspec, ReCase recase) {
    var lower = recase.snakeCase;
    var lib = new LibraryBuilder('${pubspec.name}.routes.controllers.$lower');
    lib.addDirective(
        new ImportBuilder('package:angel_common/angel_common.dart'));

    var clazz = new ClassBuilder('${recase.pascalCase}Controller',
        asExtends: new TypeBuilder('Controller'));

    // Add @Expose()
    clazz.addAnnotation(_expose('/$lower'));

    // Add
    // @Expose(path: '/')
    // String foo() => 'bar';

    var meth = new MethodBuilder('foo',
        returns: literal('bar'), returnType: new TypeBuilder('String'));
    meth.addAnnotation(_expose('/'));
    clazz.addMethod(meth);

    lib.addMember(clazz);

    return prettyToSource(lib.buildAst());
  }
}
