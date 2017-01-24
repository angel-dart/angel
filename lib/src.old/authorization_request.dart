import 'grant_type.dart';

/// An authorization grant is a credential representing the resource
/// owner's authorization (to access its protected resources) used by the
/// client to obtain an access token.
abstract class AuthorizationRequest {
  GrantType get type;
}