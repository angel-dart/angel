final Map<Symbol, String> _cache = {};

String fastNameFromSymbol(Symbol s) {
  return _cache.putIfAbsent(s, () {
    String str = s.toString();
    int open = str.indexOf('"');
    int close = str.lastIndexOf('"');
    return str.substring(open + 1, close);
  });
}
