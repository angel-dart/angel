final RegExp _equ = new RegExp(r'=$');
final RegExp _sym = new RegExp(r'Symbol\("([^"]+)"\)');

/// Supports accessing members of a Map as though they were actual members.
///
/// No longer requires reflection. :)
@proxy
class Extensible {
  /// A set of custom properties that can be assigned to the server.
  ///
  /// Useful for configuration and extension.
  Map properties = {};

  noSuchMethod(Invocation invocation) {
    if (invocation.memberName != null) {
      String name = _sym.firstMatch(invocation.memberName.toString()).group(1);

      if (invocation.isMethod) {
        return Function.apply(properties[name], invocation.positionalArguments,
            invocation.namedArguments);
      } else if (invocation.isGetter) {
        return properties[name];
      } else if (invocation.isSetter) {
        return properties[name.replaceAll(_equ, '')] =
            invocation.positionalArguments.first;
      }
    }

    super.noSuchMethod(invocation);
  }
}
