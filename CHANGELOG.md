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
