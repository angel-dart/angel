library angel_framework.test.common;

import 'package:angel_framework/src/defs.dart';

class Todo extends MemoryModel {
  String text;
  String over;

  Todo({String this.text, String this.over});
}
