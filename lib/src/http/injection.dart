part of angel_framework.http.request_context;

const List<Type> _primitiveTypes = const [String, int, num, double, Null];

/// Shortcut for calling [preInject], and then [handleContained].
///
/// Use this to instantly create a request handler for a DI-enabled method.
RequestHandler createDynamicHandler(handler,
    {Iterable<String> optional: const []}) {
  var injection = preInject(handler);
  injection.optional.addAll(optional ?? []);
  return handleContained(handler, injection);
}

/// Handles a request with a DI-enabled handler.
RequestHandler handleContained(handler, InjectionRequest injection) {
  return (RequestContext req, ResponseContext res) async {
    List args = [];

    void inject(requirement) {
      var propFromApp;

      if (requirement == RequestContext) {
        args.add(req);
      } else if (requirement == ResponseContext) {
        args.add(res);
      } else if (requirement is String) {
        if (req.params.containsKey(requirement)) {
          args.add(req.params[requirement]);
        } else if (req._injections.containsKey(requirement))
          args.add(req._injections[requirement]);
        else if (req.properties.containsKey(requirement))
          args.add(req.properties[requirement]);
        else if ((propFromApp = req.app.findProperty(requirement)) != null)
          args.add(propFromApp);
        else if (injection.optional.contains(requirement))
          args.add(null);
        else {
          throw new ArgumentError(
              "Cannot resolve parameter '$requirement' within handler.");
        }
      } else if (requirement is List &&
          requirement.length == 2 &&
          requirement.first is String &&
          requirement.last is Type) {
        String key = requirement.first;
        Type type = requirement.last;
        if (req.params.containsKey(key) ||
            req._injections.containsKey(key) ||
            req.properties.containsKey(key) ||
            req.app.configuration.containsKey(key) ||
            _primitiveTypes.contains(type)) {
          inject(key);
        } else
          inject(type);
      } else if (requirement is Type && requirement != dynamic) {
        if (req._injections.containsKey(requirement))
          args.add(req._injections[requirement]);
        else
          args.add(req.app.container.make(requirement));
      } else {
        throw new ArgumentError(
            '$requirement cannot be injected into a request handler.');
      }
    }

    Map<Symbol, dynamic> named = {};
    injection.required.forEach(inject);

    injection.named.forEach((k, v) {
      var name = new Symbol(k);
      if (req.params.containsKey(k))
        named[name] = v;
      else if (req._injections.containsKey(k))
        named[name] = v;
      else if (req._injections.containsKey(v) && v != dynamic)
        named[name] = v;
      else {
        try {
          named[name] = req.app.container.make(v);
        } catch (e) {
          named[name] = null;
        }
      }
    });

    var result = Function.apply(handler, args, named);
    return result is Future ? await result : result;
  };
}

/// Contains a list of the data required for a DI-enabled method to run.
///
/// This improves performance by removing the necessity to reflect a method
/// every time it is requested.
///
/// Regular request handlers can also skip DI entirely, lowering response time
/// and memory use.
class InjectionRequest {
  /// Optional, typed data that can be passed to a DI-enabled method.
  final Map<String, Type> named;

  /// A list of the arguments required for a DI-enabled method to run.
  final List required;

  /// A list of the arguments that can be null in a DI-enabled method.
  final List<String> optional;

  const InjectionRequest.constant({this.named, this.required, this.optional});

  InjectionRequest()
      : named = {},
        required = [],
        optional = [];
}

/// Predetermines what needs to be injected for a handler to run.
InjectionRequest preInject(Function handler) {
  var injection = new InjectionRequest();

  ClosureMirror closureMirror = reflect(handler);

  if (closureMirror.function.parameters.isEmpty) return injection;

  // Load parameters
  for (var parameter in closureMirror.function.parameters) {
    var name = MirrorSystem.getName(parameter.simpleName);
    var type = parameter.type.reflectedType;

    if (!parameter.isNamed) {
      if (parameter.isOptional) injection.optional.add(name);

      if (type == RequestContext || type == ResponseContext) {
        injection.required.add(type);
      } else if (name == 'req') {
        injection.required.add(RequestContext);
      } else if (name == 'res') {
        injection.required.add(ResponseContext);
      } else if (type == dynamic) {
        injection.required.add(name);
      } else {
        injection.required.add([name, type]);
      }
    } else {
      injection.named[name] = type;
    }
  }

  return injection;
}
