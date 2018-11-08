import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mustache/angel_mustache.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';

const FileSystem fs = const LocalFileSystem();

configureServer(Angel app) async {
  // Run the plug-in
  await app.configure(mustache(fs.directory('views')));

  // Render `hello.mustache`
  app.get('/', (req, res) async {
    await res.render('hello', {'name': 'world'});
  });
}
