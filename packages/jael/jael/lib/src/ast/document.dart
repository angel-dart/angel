import 'package:source_span/source_span.dart';
import 'ast_node.dart';
import 'element.dart';
import 'identifier.dart';
import 'string.dart';
import 'token.dart';

class Document extends AstNode {
  final Doctype doctype;
  final Element root;

  Document(this.doctype, this.root);

  @override
  FileSpan get span {
    if (doctype == null) return root.span;
    return doctype.span.expand(root.span);
  }
}

class HtmlComment extends ElementChild {
  final Token htmlComment;

  HtmlComment(this.htmlComment);

  @override
  FileSpan get span => htmlComment.span;
}

class Text extends ElementChild {
  final Token text;

  Text(this.text);

  @override
  FileSpan get span => text.span;
}

class Doctype extends AstNode {
  final Token lt, doctype, gt;
  final Identifier html, public;
  final StringLiteral name, url;

  Doctype(this.lt, this.doctype, this.html, this.public, this.name, this.url,
      this.gt);

  @override
  FileSpan get span {
    if (public == null) {
      return lt.span.expand(doctype.span).expand(html.span).expand(gt.span);
    }
    return lt.span
        .expand(doctype.span)
        .expand(html.span)
        .expand(public.span)
        .expand(name.span)
        .expand(url.span)
        .expand(gt.span);
  }
}
