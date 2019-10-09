import 'dart:io';

void printSeparator(String title) {
  var b = StringBuffer(title.toUpperCase());
  for (int i = b.length; i < stdout.terminalColumns; i++) {
    b.write('=');
  }
  for (int i = 0; i < 3; i++) {
    print(b);
  }
}
