import 'package:code_buffer/code_buffer.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:jael/jael.dart' as jael;
import 'package:jael_preprocessor/jael_preprocessor.dart' as jael;
import 'package:symbol_table/symbol_table.dart';
import 'package:test/test.dart';

main() {
  FileSystem fileSystem;

  setUp(() {
    fileSystem = new MemoryFileSystem();

    // a.jl
    fileSystem.file('a.jl').writeAsStringSync('<b>a.jl</b>');

    // b.jl
    fileSystem.file('b.jl').writeAsStringSync(
        '<i><include src="a.jl"><block name="greeting"><p>Hello</p></block></i>');

    // c.jl
    fileSystem.file('c.jl').writeAsStringSync(
        '<extend src="b.jl"><block name="greeting">Goodbye</block>Yes</extend>');

    // d.jl
    fileSystem.file('d.jl').writeAsStringSync(
        '<extend src="c.jl"><block name="greeting">Saluton!</block>Yes</extend>');

    // e.jl
    fileSystem.file('e.jl').writeAsStringSync(
        '<extend src="c.jl"><block name="greeting">Angel <b><block name="name">default</block></b></block></extend>');

    // fox.jl
    fileSystem.file('fox.jl').writeAsStringSync(
        '<block name="dance">The name is <block name="name"></block></block>');

    // trot.jl
    fileSystem.file('trot.jl').writeAsStringSync(
        '<extend src="fox.jl"><block name="name">CONGA <i><block name="exclaim">YEAH</block></i></block></extend>');

    // foxtrot.jl
    fileSystem.file('foxtrot.jl').writeAsStringSync(
        '<extend src="trot.jl"><block name="exclaim">framework</block></extend>');
  });

  test('blocks are replaced or kept', () async {
    var file = fileSystem.file('c.jl');
    var original = jael.parseDocument(await file.readAsString(),
        sourceUrl: file.uri, onError: (e) => throw e);
    var processed = await jael.resolve(
        original, fileSystem.directory(fileSystem.currentDirectory),
        onError: (e) => throw e);
    var buf = new CodeBuffer();
    var scope = new SymbolTable();
    const jael.Renderer().render(processed, buf, scope);
    print(buf);

    expect(
        buf.toString(),
        '''
<i>
  <b>
    a.jl
  </b>
  GoodbyeYes
</i>
    '''
            .trim());
  });

  test('block resolution is recursive', () async {
    var file = fileSystem.file('d.jl');
    var original = jael.parseDocument(await file.readAsString(),
        sourceUrl: file.uri, onError: (e) => throw e);
    var processed = await jael.resolve(
        original, fileSystem.directory(fileSystem.currentDirectory),
        onError: (e) => throw e);
    var buf = new CodeBuffer();
    var scope = new SymbolTable();
    const jael.Renderer().render(processed, buf, scope);
    print(buf);

    expect(
        buf.toString(),
        '''
<i>
  <b>
    a.jl
  </b>
  Saluton!Yes
</i>
    '''
            .trim());
  });

  test('blocks within blocks', () async {
    var file = fileSystem.file('foxtrot.jl');
    var original = jael.parseDocument(await file.readAsString(),
        sourceUrl: file.uri, onError: (e) => throw e);
    var processed = await jael.resolve(
        original, fileSystem.directory(fileSystem.currentDirectory),
        onError: (e) => throw e);
    var buf = new CodeBuffer();
    var scope = new SymbolTable();
    const jael.Renderer().render(processed, buf, scope);
    print(buf);

    expect(
        buf.toString(),
        '''
<i>
  <b>
    a.jl
  </b>
  Angel frameworkGoodbye
</i>
    '''
            .trim());
  });
}
