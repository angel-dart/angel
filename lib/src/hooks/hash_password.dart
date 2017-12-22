import 'dart:async';
import 'dart:mirrors';
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
      else if (passwordField == 'password')
        return user?.password;
      else
        return reflect(user)
            .getField(new Symbol(passwordField ?? 'password'))
            .reflectee;
    }

    _setPassword(password, user) {
      if (setPassword != null)
        return setPassword(password, user);
      else if (user is Map)
        user[passwordField ?? 'password'] = password;
      else
        reflect(user)
            .setField(new Symbol(passwordField ?? 'password'), password);
    }

    if (e.data != null) {
      applyHash(user) async {
        var password = (await _getPassword(user))?.toString();

        if (password != null) {
          var digest = h.convert(password.codeUnits);
          return _setPassword(new String.fromCharCodes(digest.bytes), user);
        }
      }

      if (e.data is Iterable) {
        var futures = await Future.wait(e.data.map((data) async {
          await applyHash(data);
          return data;
        }));

        e.data = futures.toList();
      } else
        await applyHash(e.data);
    }
  };
}
