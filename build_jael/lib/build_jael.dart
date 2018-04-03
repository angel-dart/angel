import 'dart:async';
import 'package:build/build.dart';
import 'package:code_buffer/code_buffer.dart';
import 'package:file/file.dart';
import 'package:jael/jael.dart' as jael;
import 'package:jael_preprocessor/jael_preprocessor.dart' as jael;
import 'package:symbol_table/symbol_table.dart';

Builder jaelBuilder(BuilderOptions options) => new JaelBuilder(options);

class JaelBuilder implements Builder {
  final BuilderOptions options;
  final List<jael.Patcher> patch;

  const JaelBuilder(this.options, {this.patch: const []});

  @override
  Map<String, List<String>> get buildExtensions {
    return {
      '.jl': ['.html'],
    };
  }

  @override
  Future build(BuildStep buildStep) async {
    CodeBuffer buf;

    if (options.config['minify'] == true)
      buf = new CodeBuffer(space: '', newline: '', trailingNewline: false);
    else
      buf = new CodeBuffer();

    Directory dir;

    var errors = <jael.JaelError>[];

    var doc = await jael.parseDocument(
      await buildStep.readAsString(buildStep.inputId),
      sourceUrl: buildStep.inputId.uri,
      onError: errors.add,
    );

    doc = await jael.resolve(
      doc,
      dir,
      onError: errors.add,
      patch: this.patch,
    );

    if (errors.isNotEmpty) {
      jael.Renderer.errorDocument(errors, buf);
    } else {
      var scope = new SymbolTable(values: new Map.from(options.config));

      try {
        const jael.Renderer().render(
          doc,
          buf,
          scope,
          strictResolution: options.config['strict'] == true,
        );
      } on jael.JaelError catch (e) {
        errors.add(e);
      }

      if (errors.isNotEmpty) {
        jael.Renderer.errorDocument(errors, buf);
      }
    }

    buildStep.writeAsString(
      buildStep.inputId.changeExtension('.html'),
      buf.toString(),
    );
  }
}
