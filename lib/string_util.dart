/// Helper functions to performantly transform strings, without `RegExp`.
library angel_route.string_util;

/// Removes leading and trailing occurrences of a pattern from a string.
String stripStray(String haystack, String needle) {
  int firstSlash;

  if (haystack.startsWith(needle)) {
    firstSlash = haystack.indexOf(needle);
    if (firstSlash == -1) return haystack;
  } else {
    firstSlash = -1;
  }

  if (firstSlash == haystack.length - 1)
    return haystack.length == 1 ? '' : haystack.substring(0, firstSlash);

  // Find last leading index of slash
  for (int i = firstSlash + 1; i < haystack.length; i++) {
    if (haystack[i] != needle) {
      var sub = haystack.substring(i);

      if (!sub.endsWith(needle))
        return sub;

      var lastSlash = sub.lastIndexOf(needle);

      for (int j = lastSlash - 1; j >= 0; j--) {
        if (sub[j] != needle) {
          return sub.substring(0, j + 1);
        }
      }

      return lastSlash == -1 ? sub : sub.substring(0, lastSlash);
    }
  }

  return haystack.substring(0, firstSlash);
}

String stripStraySlashes(String str) => stripStray(str, '/');

String stripRegexStraySlashes(String str) => stripStray(str, '\\/');
