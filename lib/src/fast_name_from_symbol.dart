String fastNameFromSymbol(Symbol s) {
  String str = s.toString();
  int open = str.indexOf('"');
  int close = str.lastIndexOf('"');
  return str.substring(open + 1, close);
}