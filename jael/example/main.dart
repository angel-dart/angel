import 'dart:io';
import 'package:charcode/charcode.dart';
import 'package:code_buffer/code_buffer.dart';
import 'package:jael/jael.dart' as jael;
import 'package:symbol_table/symbol_table.dart';

main() {
  while (true) {
    var buf = new StringBuffer();
    int ch;
    print('Enter lines of Jael text, terminated by CTRL^D.');
    print('All environment variables are injected into the template scope.');

    while ((ch = stdin.readByteSync()) != $eot && ch != -1) {
      buf.writeCharCode(ch);
    }

    var document = jael.parseDocument(
      buf.toString(),
      sourceUrl: 'stdin',
      onError: stderr.writeln,
    );

    if (document == null) {
      stderr.writeln('Could not parse the given text.');
    } else {
      var output = new CodeBuffer();
      const jael.Renderer().render(
        document,
        output,
        new SymbolTable(values: Platform.environment),
        strictResolution: false,
      );
      print('GENERATED HTML:\n$output');
    }
  }
}
