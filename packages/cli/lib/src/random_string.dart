import 'dart:math';

const String _valid =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
final Random _rnd = new Random.secure();

String randomAlphaNumeric(int length) {
  var b = new StringBuffer();

  for (int i = 0; i < length; i++) {
    b.writeCharCode(_valid.codeUnitAt(_rnd.nextInt(_valid.length)));
  }

  return b.toString();
}
