import 'package:angel_framework/angel_framework.dart';

/// A base class that facilitates rate limiting API's or endpoints,
/// typically to prevent spam and abuse.
abstract class RateLimiter {
  /// The maximum number of requests allowed within the given [window].
  final int maxRequestsPerWindow;

  /// The amount of time, during which, a user is not allowed to send
  /// more than [maxRequestsPerWindow].
  final Duration window;

  RateLimiter(this.maxRequestsPerWindow, this.window);
}
