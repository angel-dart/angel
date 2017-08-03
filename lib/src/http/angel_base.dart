library angel_framework.http.angel_base;

import 'dart:async';
import 'package:container/container.dart';
import '../fast_name_from_symbol.dart';
import 'routable.dart';

/// A function that asynchronously generates a view from the given path and data.
typedef Future<String> ViewGenerator(String path, [Map data]);

/// Base class for Angel servers. Do not bother extending this.
@proxy
class AngelBase extends Routable {
  Container _container = new Container();

  final Map properties = {};

  /// When set to true, the request body will not be parsed
  /// automatically. You can call `req.parse()` manually,
  /// or use `lazyBody()`.
  bool lazyParseBodies = false;

  /// When set to `true`, the original body bytes will be stored
  /// on requests. `false` by default.
  bool storeOriginalBuffer = false;

  /// A [Container] used to inject dependencies.
  Container get container => _container;

  /// A function that renders views.
  ///
  /// Called by [ResponseContext]@`render`.
  ViewGenerator viewGenerator = (String view, [Map data]) async => "No view engine has been configured yet.";

  operator [](key) => properties[key];
  operator []=(key, value) => properties[key] = value;

  noSuchMethod(Invocation invocation) {
    if (invocation.memberName != null) {
      String name = fastNameFromSymbol(invocation.memberName);

      if (invocation.isMethod) {
        return Function.apply(properties[name], invocation.positionalArguments,
            invocation.namedArguments);
      } else if (invocation.isGetter) {
        return properties[name];
      }
    }

    return super.noSuchMethod(invocation);
  }
}