/// The four grant types defined in the OAuth2 specification.
enum GrantType {
  AUTHORIZATION_CODE,
  IMPLICIT,
  RESOURCE_OWNER_PASSWORD_CREDENTIALS,
  CLIENT_CREDENTIALS,
  // TODO: OTHER
}

/// `String` representations of the four main grant types.
const Map<GrantType, String> GRANT_TYPES = const {
  GrantType.AUTHORIZATION_CODE: 'authorization_code',
  GrantType.IMPLICIT: 'implicit'
  // TODO: RESOURCE_OWNER_PASSWORD_CREDENTIALS
  // TODO: CLIENT_CREDENTIALS
};
