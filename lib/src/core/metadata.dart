library angel_framework.http.metadata;

import 'package:angel_http_exception/angel_http_exception.dart';

import 'hooked_service.dart' show HookedServiceEventListener;
import 'request_context.dart';
import 'routable.dart';

/// Annotation to map middleware onto a handler.
class Middleware {
  final Iterable<RequestHandler> handlers;

  const Middleware(this.handlers);
}

/// Attaches hooks to a [HookedService].
class Hooks {
  final List<HookedServiceEventListener> before;
  final List<HookedServiceEventListener> after;

  const Hooks({this.before = const [], this.after = const []});
}

/// Exposes a [Controller] or a [Controller] method to the Internet.
///
/// ```dart
/// @Expose('/elements')
/// class ElementController extends Controller {
///
///   @Expose('')
///   getList(){}
///
///   @Expose('/:elementId')
///   getElement(int elementId){}
///
/// }
/// ```
class Expose {
  final String method;
  final String path;
  final Iterable<RequestHandler> middleware;
  final String as;
  final List<String> allowNull;

  const Expose(this.path,
      {this.method = "GET",
      this.middleware = const [],
      this.as,
      this.allowNull = const []});
}

/// Used to apply special dependency injections or functionality to a function parameter.
class Parameter {
  /// Inject the value of a request cookie.
  final String cookie;

  /// Inject the value of a request header.
  final String header;

  /// Inject the value of a key from the session.
  final String session;

  /// Inject the value of a key from the query.
  final String query;

  /// Only execute the handler if the value of this parameter matches the given value.
  final match;

  /// Specify a default value.
  final defaultValue;

  /// If `true` (default), then an error will be thrown if this parameter is not present.
  final bool required;

  const Parameter(
      {this.cookie,
      this.query,
      this.header,
      this.session,
      this.match,
      this.defaultValue,
      this.required});

  /// Returns an error that can be thrown when the parameter is not present.
  get error {
    if (cookie?.isNotEmpty == true) {
      return AngelHttpException.badRequest(
          message: 'Missing required cookie "$cookie".');
    }
    if (header?.isNotEmpty == true) {
      return AngelHttpException.badRequest(
          message: 'Missing required header "$header".');
    }
    if (query?.isNotEmpty == true) {
      return AngelHttpException.badRequest(
          message: 'Missing required query parameter "$query".');
    }
    if (session?.isNotEmpty == true) {
      return StateError('Session does not contain required key "$session".');
    }
  }

  /// Obtains a value for this parameter from a [RequestContext].
  getValue(RequestContext req) {
    if (cookie?.isNotEmpty == true) {
      return req.cookies.firstWhere((c) => c.name == cookie)?.value ??
          defaultValue;
    }
    if (header?.isNotEmpty == true) {
      return req.headers.value(header) ?? defaultValue;
    }
    if (session?.isNotEmpty == true) {
      return req.session[session] ?? defaultValue;
    }
    if (query?.isNotEmpty == true) {
      return req.uri.queryParameters[query] ?? defaultValue;
    }
    return defaultValue;
  }
}

/// Shortcut for declaring a request header [Parameter].
class Header extends Parameter {
  const Header(String header, {match, defaultValue, bool required = true})
      : super(
            header: header,
            match: match,
            defaultValue: defaultValue,
            required: required);
}

/// Shortcut for declaring a request session [Parameter].
class Session extends Parameter {
  const Session(String session, {match, defaultValue, bool required = true})
      : super(
            session: session,
            match: match,
            defaultValue: defaultValue,
            required: required);
}

/// Shortcut for declaring a request query [Parameter].
class Query extends Parameter {
  const Query(String query, {match, defaultValue, bool required = true})
      : super(
            query: query,
            match: match,
            defaultValue: defaultValue,
            required: required);
}

/// Shortcut for declaring a request cookie [Parameter].
class CookieValue extends Parameter {
  const CookieValue(String cookie, {match, defaultValue, bool required = true})
      : super(
            cookie: cookie,
            match: match,
            defaultValue: defaultValue,
            required: required);
}
