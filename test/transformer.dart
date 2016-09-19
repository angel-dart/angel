import 'package:analyzer/analyzer.dart';
import 'package:angel_configuration/transformer.dart';
import 'package:test/test.dart';

main() {
  test("simple replacement", () async {
    var visitor = new ConfigAstVisitor({"foo": "bar"});
    var source = '''
    import 'package:angel_configuration/browser.dart';

    main() async {
        var foo = config('foo');
    }
    ''';

    var compilationUnit = parseCompilationUnit(source);
    visitor.visitCompilationUnit(compilationUnit);

    var replaced = await visitor.onReplaced.take(2).last;

    expect(replaced["needle"], equals("config('foo')"));
    expect(replaced["with"], equals('"bar"'));

    print(source.replaceAll(replaced["needle"], replaced["with"]));
  });
}
