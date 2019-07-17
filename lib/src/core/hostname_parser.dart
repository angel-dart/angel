import 'dart:collection';
import 'package:string_scanner/string_scanner.dart';

/// Parses a string into a [RegExp] that is matched against hostnames.
class HostnameSyntaxParser {
  final SpanScanner _scanner;
  var _safe = RegExp(r"[0-9a-zA-Z-_]+");

  HostnameSyntaxParser(String hostname) : _scanner = SpanScanner(hostname);

  RegExp parse() {
    var b = StringBuffer();
    var parts = Queue<String>();

    while (!_scanner.isDone) {
      if (_scanner.scan('|')) {
        if (parts.isEmpty) {
          throw FormatException(
              '${_scanner.emptySpan.end.toolString}: No hostname parts found before "|".');
        } else {
          var next = _parseHostnamePart();
          if (next == null) {
            throw FormatException(
                '${_scanner.emptySpan.end.toolString}: No hostname parts found after "|".');
          } else {
            var prev = parts.removeLast();
            parts.addLast('(($prev)|($next))');
          }
        }
      } else {
        var part = _parseHostnamePart();
        if (part != null) {
          parts.add(part);
        }
      }
    }

    while (parts.isNotEmpty) {
      b.write(parts.removeFirst());
    }

    if (b.isEmpty) {
      throw FormatException('Invalid or empty hostname.');
    } else {
      return RegExp(b.toString(), caseSensitive: false);
    }
  }

  String _parseHostnamePart() {
    if (_scanner.scan('*.')) {
      return r'([^$]+\.)?';
    } else if (_scanner.scan('*')) {
      return r'[^$]*';
    } else if (_scanner.scan(_safe)) {
      return _scanner.lastMatch[0];
    } else if (!_scanner.isDone) {
      var s = String.fromCharCode(_scanner.peekChar());
      throw FormatException(
          '${_scanner.emptySpan.end.toolString}: Unexpected character "$s".');
    } else {
      return null;
    }
  }
}
