import 'dart:html';
import 'package:angel_route/browser.dart';

basic(BrowserRouter router) {
  final $h1 = window.document.querySelector('h1');
  final $ul = window.document.getElementById('handlers');

  router.onResolve.listen((result) {
    final route = result?.route;

    if (route == null) {
      $h1.text = 'No Active Route';
      $ul.children
        ..clear()
        ..add(LIElement()..text = '(empty)');
    } else {
      $h1.text = 'Active Route: ${route.name ?? route.path}';
      $ul.children
        ..clear()
        ..addAll(result.allHandlers
            .map((handler) => LIElement()..text = handler.toString()));
    }
  });

  router.get('a', 'a handler');

  router.group('b', (router) {
    router.get('a', 'b/a handler').name = 'b/a';
    router.get('b', 'b/b handler', middleware: ['b/b middleware']).name = 'b/b';
  }, middleware: ['b middleware']);

  router.get('c', 'c handler');

  router
    ..dumpTree()
    ..listen();
}
