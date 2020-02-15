import 'dart:collection';
import 'package:string_scanner/string_scanner.dart';

/// Parses a string into a [RegExp] that is matched against hostnames.
class HostnameSyntaxParser {
  final SpanScanner _scanner;
  var _safe = RegExp(r"[0-9a-zA-Z-_:]+");

  HostnameSyntaxParser(String hostname)
      : _scanner = SpanScanner(hostname, sourceUrl: hostname);

  FormatException _formatExc(String message) {
    var span = _scanner.lastSpan ?? _scanner.emptySpan;
    return FormatException(
        '${span.start.toolString}: $message\n' + span.highlight(color: true));
  }

  RegExp parse() {
    var b = StringBuffer();
    var parts = Queue<String>();

    while (!_scanner.isDone) {
      if (_scanner.scan('|')) {
        if (parts.isEmpty) {
          throw _formatExc('No hostname parts found before "|".');
        } else {
          var next = _parseHostnamePart();
          if (next == null) {
            throw _formatExc('No hostname parts found after "|".');
          } else {
            var prev = parts.removeLast();
            parts.addLast('(($prev)|($next))');
          }
        }
      } else {
        var part = _parseHostnamePart();
        if (part != null) {
          if (_scanner.scan('.')) {
            var subPart = _parseHostnamePart(shouldThrow: false);
            while (subPart != null) {
              part += '\\.' + subPart;
              if (_scanner.scan('.')) {
                subPart = _parseHostnamePart(shouldThrow: false);
              } else {
                break;
              }
            }
          }

          parts.add(part);
        }
      }
    }

    while (parts.isNotEmpty) {
      b.write(parts.removeFirst());
    }

    if (b.isEmpty) {
      throw _formatExc('Invalid or empty hostname.');
    } else {
      return RegExp('^$b\$', caseSensitive: false);
    }
  }

  String _parseHostnamePart({bool shouldThrow = true}) {
    if (_scanner.scan('*.')) {
      return r'([^$.]+\.)?';
    } else if (_scanner.scan('*')) {
      return r'[^$]*';
    } else if (_scanner.scan('+')) {
      return r'[^$]+';
    } else if (_scanner.scan(_safe)) {
      return _scanner.lastMatch[0];
    } else if (!_scanner.isDone && shouldThrow) {
      var s = String.fromCharCode(_scanner.peekChar());
      throw _formatExc('Unexpected character "$s".');
    } else {
      return null;
    }
  }
}
