import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:angel_framework/angel_framework.dart';

/// Hashes a user's password using a [Hash] algorithm (Default: [sha256]).
///
/// You may provide your own functions to obtain or set a user's password,
/// or just provide a [passwordField] if you are only ever going to deal with Maps.
HookedServiceEventListener hashPassword(
    {Hash hasher,
    String passwordField,
    getPassword(user),
    setPassword(password, user)}) {
  Hash h = hasher ?? sha256;

  return (HookedServiceEvent e) async {
    _getPassword(user) {
      if (getPassword != null)
        return getPassword(user);
      else if (user is Map)
        return user[passwordField ?? 'password'];
      else
        return user?.password;
    }

    _setPassword(password, user) {
      if (setPassword != null)
        return setPassword(password, user);
      else if (user is Map)
        user[passwordField ?? 'password'] = password;
      else
        user?.password = password;
    }

    if (e.data != null) {
      var password;

      if (e.data is Iterable) {
        for (var data in e.data) {
          var p = await _getPassword(data);

          if (p != null) {
            password = p;
            break;
          }
        }
      } else
        password = await _getPassword(e.data);

      if (password != null) {
        applyHash(user) async {
          var password = (await _getPassword(user))?.toString();
          var digest = h.convert(password.codeUnits);
          return _setPassword(new String.fromCharCodes(digest.bytes), user);
        }

        if (e.data is Iterable) {
          var data = await Future.wait(e.data.map(applyHash));
          e.data = e.data is List ? data.toList() : data;
        } else
          e.data = await applyHash(e.data);

        // TODO (thosakwe): Add salting capability
      }
    }
  };
}
