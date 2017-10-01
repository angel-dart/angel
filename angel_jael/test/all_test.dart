import 'package:angel_framework/angel_framework.dart';
import 'package:angel_jael/angel_jael.dart';
import 'package:angel_test/angel_test.dart';
import 'package:file/memory.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

main() {
  // These tests need not actually test that the preprocessor or renderer works,
  // because those packages are already tested.
  //
  // Instead, just test that we can render at all.
  TestClient client;

  setUp(() async {
    var app = new Angel();
    app.configuration['properties'] = app.configuration;

    var fileSystem = new MemoryFileSystem();
    var viewsDirectory = fileSystem.directory('views')..createSync();

    viewsDirectory.childFile('layout.jl').writeAsStringSync('''
<!DOCTYPE html>
<html>
  <head>
    <title>Hello</title>
  </head>
  <body>
    <block name="content">
      Fallback content
    </block>
  </body>
</html>
    ''');

    viewsDirectory.childFile('github.jl').writeAsStringSync('''
<extend src="layout.jl">
  <block name="content">{{username}}</block>
</extend>
    ''');

    app.get('/github/:username', (String username, ResponseContext res) {
      return res.render('github', {'username': username});
    });

    await app.configure(
      jael(viewsDirectory),
    );

    app.use(() => throw new AngelHttpException.notFound());

    app.logger = new Logger('angel')
      ..onRecord.listen((rec) {
        print(rec);
        if (rec.error != null) print(rec.error);
        if (rec.stackTrace != null) print(rec.stackTrace);
      });

    client = await connectTo(app);
  });

  test('can render', () async {
    var response = await client.get('/github/thosakwe');
    print('Body:\n${response.body}');

    expect(
        response,
        hasBody('''
<!DOCTYPE html>
<html>
  <head>
    <title>
      Hello
    </title>
  </head>
  <body>
    thosakwe
  </body>
</html>
    '''
            .trim()));
  });
}
