library user_agent;

import 'src/matchers.dart';
import 'src/user_agent.dart';

/// Parses the given header into a user agent.
UserAgent parse(String header) {}

class UserAgentException implements Exception {
  final String message;
  
  UserAgentException(this.message);
  
  @override
  String toString() => 'User Agent exception: $message';
}
