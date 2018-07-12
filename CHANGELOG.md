# 1.2.0
* Deprecate `requireAuth`, in favor of `requireAuthentication`.
* Allow configuring of the `userKey`.
* Add `authenticateAndContinue`.
* Deprecate `middlewareName`.

# 1.1.1+6
* Fix a small logic bug that prevented `LocalAuthStrategy`
from correctly propagating the authenticated user when
using `Basic` auth.

# 1.1.1+5
* Prevent duplication of cookies.
* Regenerate the JWT if `tokenCallback` is called.

# 1.1.1+4
* Patched `logout` to properly erase cookies
* Fixed checking of expired tokens.

# 1.1.1+3
* `authenticate` returns the current user, if one is present.

# 1.1.1+2
* `_apply` now always sends a `token` cookie.

# 1.1.1+1
* Update `protectCookie` to only send `maxAge` when it is not `-1`.

# 1.1.1
* Added `protectCookie`, to better protect data sent in cookies.

# 1.1.0+2
* `LocalAuthStrategy` returns `true` on `Basic` authentication.

# 1.1.0+1
* Modified `LocalAuthStrategy`'s handling of `Basic` authentication.
