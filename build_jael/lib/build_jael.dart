import 'dart:async';
import 'package:build/build.dart';
import 'package:code_buffer/code_buffer.dart';
import 'package:file/file.dart';
import 'package:jael/jael.dart' as jael;
import 'package:jael_preprocessor/jael_preprocessor.dart';

class JaelBuilder implements Builder {
  final BuilderOptions options;

  const JaelBuilder(this.options);

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

    if (errors.isNotEmpty) {}
  }
}
