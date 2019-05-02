part of angel_framework.http.request_context;

const List<Type> _primitiveTypes = [String, int, num, double, Null];

/// Shortcut for calling [preInject], and then [handleContained].
///
/// Use this to instantly create a request handler for a DI-enabled method.
///
/// Calling [ioc] also auto-serializes the result of a [handler].
RequestHandler ioc(Function handler, {Iterable<String> optional = const []}) {
  InjectionRequest injection;
  RequestHandler contained;

  return (req, res) {
    if (injection == null) {
      injection = preInject(handler, req.app.container.reflector);
      injection.optional.addAll(optional ?? []);
      contained = handleContained(handler, injection);
    }

    return req.app.executeHandler(contained, req, res);
  };
}

resolveInjection(requirement, InjectionRequest injection, RequestContext req,
    ResponseContext res, bool throwOnUnresolved,
    [Container container]) async {
  var propFromApp;
  container ??= req?.container ?? res?.app?.container;

  if (requirement == RequestContext) {
    return req;
  } else if (requirement == ResponseContext) {
    return res;
  } else if (requirement is String &&
      injection.parameters.containsKey(requirement)) {
    var param = injection.parameters[requirement];
    var value = param.getValue(req);
    if (value == null && param.required != false) throw param.error;
    return value;
  } else if (requirement is String) {
    if (req.container.hasNamed(requirement))
      return req.container.findByName(requirement);
    if (req.params.containsKey(requirement)) {
      return req.params[requirement];
    } else if ((propFromApp = req.app.findProperty(requirement)) != null)
      return propFromApp;
    else if (injection.optional.contains(requirement))
      return null;
    else if (throwOnUnresolved) {
      throw ArgumentError(
          "Cannot resolve parameter '$requirement' within handler.");
    }
  } else if (requirement is List &&
      requirement.length == 2 &&
      requirement.first is String &&
      requirement.last is Type) {
    var key = requirement.first;
    var type = requirement.last;
    if (req.params.containsKey(key) ||
        req.app.configuration.containsKey(key) ||
        _primitiveTypes.contains(type)) {
      return await resolveInjection(
          key, injection, req, res, throwOnUnresolved, container);
    } else
      return await resolveInjection(
          type, injection, req, res, throwOnUnresolved, container);
  } else if (requirement is Type && requirement != dynamic) {
    try {
      var futureType = container.reflector.reflectFutureOf(requirement);
      if (container.has(futureType.reflectedType))
        return await container.make(futureType.reflectedType);
    } on UnsupportedError {
      // Ignore.
    }

    return await container.make(requirement);
  } else if (throwOnUnresolved) {
    throw ArgumentError(
        '$requirement cannot be injected into a request handler.');
  }
}

/// Checks if an [InjectionRequest] can be sufficiently executed within the current request/response context.
bool suitableForInjection(
    RequestContext req, ResponseContext res, InjectionRequest injection) {
  return injection.parameters.values.any((p) {
    if (p.match == null) return false;
    var value = p.getValue(req);
    return value == p.match;
  });
}

/// Handles a request with a DI-enabled handler.
RequestHandler handleContained(Function handler, InjectionRequest injection,
    [Container container]) {
  return (RequestContext req, ResponseContext res) async {
    if (injection.parameters.isNotEmpty &&
        injection.parameters.values.any((p) => p.match != null) &&
        !suitableForInjection(req, res, injection)) return Future.value(true);

    List args = [];

    Map<Symbol, dynamic> named = {};

    for (var r in injection.required) {
      args.add(await resolveInjection(r, injection, req, res, true, container));
    }

    for (var entry in injection.named.entries) {
      var name = Symbol(entry.key);
      named[name] = await resolveInjection(
          [entry.key, entry.value], injection, req, res, false, container);
    }

    return Function.apply(handler, args, named);
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

  /// Extended parameter definitions.
  final Map<String, Parameter> parameters;

  const InjectionRequest.constant(
      {this.named = const {},
      this.required = const [],
      this.optional = const [],
      this.parameters = const {}});

  InjectionRequest()
      : named = {},
        required = [],
        optional = [],
        parameters = {};
}

/// Predetermines what needs to be injected for a handler to run.
InjectionRequest preInject(Function handler, Reflector reflector) {
  var injection = InjectionRequest();

  var closureMirror = reflector.reflectFunction(handler);

  if (closureMirror.parameters.isEmpty) return injection;

  // Load parameters
  for (var parameter in closureMirror.parameters) {
    var name = parameter.name;
    var type = parameter.type.reflectedType;

    var _Parameter = reflector.reflectType(Parameter);

    var p = parameter.annotations
        .firstWhere((m) => m.type.isAssignableTo(_Parameter),
            orElse: () => null)
        ?.reflectee as Parameter;
    //print(p);
    if (p != null) {
      injection.parameters[name] = Parameter(
        cookie: p.cookie,
        header: p.header,
        query: p.query,
        session: p.session,
        match: p.match,
        defaultValue: p.defaultValue,
        required: parameter.isNamed ? false : p.required != false,
      );
    }

    if (!parameter.isNamed) {
      if (!parameter.isRequired) injection.optional.add(name);

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
