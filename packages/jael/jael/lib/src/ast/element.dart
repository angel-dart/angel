import 'package:source_span/source_span.dart';
import 'ast_node.dart';
import 'attribute.dart';
import 'identifier.dart';
import 'token.dart';

abstract class ElementChild extends AstNode {}

class TextNode extends ElementChild {
  final Token text;

  TextNode(this.text);

  @override
  FileSpan get span => text.span;
}

abstract class Element extends ElementChild {
  static const List<String> selfClosing = [
    'include',
    'base',
    'basefont',
    'frame',
    'link',
    'meta',
    'area',
    'br',
    'col',
    'hr',
    'img',
    'input',
    'param',
  ];

  Identifier get tagName;

  Iterable<Attribute> get attributes;

  Iterable<ElementChild> get children;

  Attribute getAttribute(String name) =>
      attributes.firstWhere((a) => a.name == name, orElse: () => null);
}

class SelfClosingElement extends Element {
  final Token lt, slash, gt;

  final Identifier tagName;

  final Iterable<Attribute> attributes;

  @override
  Iterable<ElementChild> get children => [];

  SelfClosingElement(
      this.lt, this.tagName, this.attributes, this.slash, this.gt);

  @override
  FileSpan get span {
    var start = attributes.fold<FileSpan>(
        lt.span.expand(tagName.span), (out, a) => out.expand(a.span));
    return slash != null
        ? start.expand(slash.span).expand(gt.span)
        : start.expand(gt.span);
  }
}

class RegularElement extends Element {
  final Token lt, gt, lt2, slash, gt2;

  final Identifier tagName, tagName2;

  final Iterable<Attribute> attributes;

  final Iterable<ElementChild> children;

  RegularElement(this.lt, this.tagName, this.attributes, this.gt, this.children,
      this.lt2, this.slash, this.tagName2, this.gt2);

  @override
  FileSpan get span {
    var openingTag = attributes
        .fold<FileSpan>(
            lt.span.expand(tagName.span), (out, a) => out.expand(a.span))
        .expand(gt.span);

    if (gt2 == null) return openingTag;

    return children
        .fold<FileSpan>(openingTag, (out, c) => out.expand(c.span))
        .expand(lt2.span)
        .expand(slash.span)
        .expand(tagName2.span)
        .expand(gt2.span);
  }
}
