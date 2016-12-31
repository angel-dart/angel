library angel_framework.http.angel_base;

import 'dart:async';
import 'package:container/container.dart';
import 'routable.dart';

/// A function that asynchronously generates a view from the given path and data.
typedef Future<String> ViewGenerator(String path, [Map data]);

/// Base class for Angel servers. Do not bother extending this.
class AngelBase extends Routable {
  AngelBase({bool debug: false}):super(debug: debug);

  Container _container = new Container();

  /// A [Container] used to inject dependencies.
  Container get container => _container;

  /// A function that renders views.
  ///
  /// Called by [ResponseContext]@`render`.
  ViewGenerator viewGenerator = (String view,
      [Map data]) async => "No view engine has been configured yet.";
}