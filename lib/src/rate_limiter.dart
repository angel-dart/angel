import 'dart:async';
import 'package:angel_framework/angel_framework.dart';

/// A base class that facilitates rate limiting API's or endpoints,
/// typically to prevent spam and abuse.
///
/// The rate limiter operates under the assumption that a [User] object
/// can be computed from each request, as well as information about
/// the current rate-limiting window.
abstract class RateLimiter<User> {
  /// The maximum number of requests allowed within the given [window].
  final int maxRequestsPerWindow;

  /// The amount of time, during which, a user is not allowed to send
  /// more than [maxRequestsPerWindow].
  final Duration window;

  RateLimiter(this.maxRequestsPerWindow, this.window);
}
