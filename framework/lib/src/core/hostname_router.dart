import 'dart:async';
import 'package:angel_container/angel_container.dart';
import 'package:angel_route/angel_route.dart';
import 'package:logging/logging.dart';
import 'env.dart';
import 'hostname_parser.dart';
import 'request_context.dart';
import 'response_context.dart';
import 'routable.dart';
import 'server.dart';

/// A utility that allows requests to be handled based on their
/// origin's hostname.
///
/// For example, an application could handle example.com and api.example.com
/// separately.
///
/// The provided patterns can be any `Pattern`. If a `String` is provided, a simple
/// grammar (see [HostnameSyntaxParser]) is used to create [RegExp].
///
/// For example:
/// * `example.com` -> `/example\.com/`
/// * `*.example.com` -> `/([^$.]\.)?example\.com/`
/// * `example.*` -> `/example\./[^$]*`
/// * `example.+` -> `/example\./[^$]+`
class HostnameRouter {
  final Map<Pattern, Angel> _apps = {};
  final Map<Pattern, FutureOr<Angel> Function()> _creators = {};
  final List<Pattern> _patterns = [];

  HostnameRouter(
      {Map<Pattern, Angel> apps = const {},
      Map<Pattern, FutureOr<Angel> Function()> creators = const {}}) {
    Map<Pattern, V> _parseMap<V>(Map<Pattern, V> map) {
      return map.map((p, c) {
        Pattern pp;

        if (p is String) {
          pp = HostnameSyntaxParser(p).parse();
        } else {
          pp = p;
        }

        return MapEntry(pp, c);
      });
    }

    apps ??= {};
    creators ??= {};
    apps = _parseMap(apps);
    creators = _parseMap(creators);
    var patterns = apps.keys.followedBy(creators.keys).toSet().toList();
    _apps.addAll(apps);
    _creators.addAll(creators);
    _patterns.addAll(patterns);
    // print(_creators);
  }

  factory HostnameRouter.configure(
      Map<Pattern, FutureOr<void> Function(Angel)> configurers,
      {Reflector reflector = const EmptyReflector(),
      AngelEnvironment environment = angelEnv,
      Logger logger,
      bool allowMethodOverrides = true,
      FutureOr<String> Function(dynamic) serializer,
      ViewGenerator viewGenerator}) {
    var creators = configurers.map((p, c) {
      return MapEntry(p, () async {
        var app = Angel(
            reflector: reflector,
            environment: environment,
            logger: logger,
            allowMethodOverrides: allowMethodOverrides,
            serializer: serializer,
            viewGenerator: viewGenerator);
        await app.configure(c);
        return app;
      });
    });
    return HostnameRouter(creators: creators);
  }

  /// Attempts to handle a request, according to its hostname.
  ///
  /// If none is matched, then `true` is returned.
  /// Also returns `true` if all of the sub-app's handlers returned
  /// `true`.
  Future<bool> handleRequest(RequestContext req, ResponseContext res) async {
    if (req.hostname != null) {
      for (var pattern in _patterns) {
        // print('${req.hostname} vs $_creators');
        if (pattern.allMatches(req.hostname).isNotEmpty) {
          // Resolve the entire pipeline within the context of the selected app.
          var app = _apps[pattern] ??= (await _creators[pattern]());
          // print('App for ${req.hostname} = $app from $pattern');
          // app.dumpTree();

          var r = app.optimizedRouter;
          var resolved = r.resolveAbsolute(req.path, method: req.method);
          var pipeline = MiddlewarePipeline<RequestHandler>(resolved);
          // print('Pipeline: $pipeline');
          for (var handler in pipeline.handlers) {
            // print(handler);
            // Avoid stack overflow.
            if (handler == handleRequest) {
              continue;
            } else if (!await app.executeHandler(handler, req, res)) {
              // print('$handler TERMINATED');
              return false;
            } else {
              // print('$handler CONTINUED');
            }
          }
        }
      }
    }

    // Otherwise, return true.
    return true;
  }
}
