import 'package:angel_framework/angel_framework.dart';
import 'package:angel_wings/angel_wings.dart';

main() async {
  var app = Angel();
  var wings1 = AngelWings.custom(app, startSharedWings);
  var wings2 = AngelWings.custom(app, startSharedWings);
  var wings3 = AngelWings.custom(app, startSharedWings);
  var wings4 = AngelWings.custom(app, startSharedWings);
  await wings1.startServer('127.0.0.1', 3000);
  await wings2.startServer('127.0.0.1', 3000);
  await wings3.startServer('127.0.0.1', 3000);
  await wings4.startServer('127.0.0.1', 3000);
  print(wings1.uri);
  print(wings2.uri);
  print(wings3.uri);
  print(wings4.uri);
  await wings1.close();
  await wings2.close();
  await wings3.close();
  await wings4.close();
}
