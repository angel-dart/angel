import 'dart:async';
import 'authorization_request.dart';

/// An application making protected resource requests on behalf of the
/// resource owner and with its authorization.  The term "client" does
/// not imply any particular implementation characteristics (e.g.,
/// whether the application executes on a server, a desktop, or other
/// devices).
abstract class Client extends Stream<AuthorizationRequest> {}
