import 'package:angel_configuration/angel_configuration.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:file/local.dart';

main() async {
  var app = new Angel();
  var fs = const LocalFileSystem();
  await app.configure(configuration(fs));
}
