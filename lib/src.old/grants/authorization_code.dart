import '../authorization_request.dart';
import '../grant_type.dart';

///  The authorization code is obtained by using an authorization server
/// as an intermediary between the client and resource owner. Instead of
/// requesting authorization directly from the resource owner, the client
/// directs the resource owner to an authorization server (via its
/// user-agent as defined in [RFC2616]), which in turn directs the
/// resource owner back to the client with the authorization code.
class AuthorizationCodeGrantRequest implements AuthorizationRequest {
  @override
  GrantType get type => GrantType.AUTHORIZATION_CODE;
}
