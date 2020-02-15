import 'dom_builder.dart';
import 'dom_node.dart';

abstract class BuilderNode extends DomNode {
  DomBuilderElement<T> build<T>(DomBuilder<T> dom);

  void destroy<T>(DomBuilderElement<T> el);
}

DomNode h(String tagName,
    [Map<String, dynamic> props = const {},
    Iterable<DomNode> children = const []]) {
  return _H(tagName, props, children);
}

DomNode text(String value) => _Text(value);

class _Text extends BuilderNode {
  final String text;

  _Text(this.text);

  @override
  DomBuilderElement<T> build<T>(DomBuilder<T> dom) {
    dom.text(text);
    // TODO: implement build
    return null;
  }

  @override
  void destroy<T>(DomBuilderElement<T> el) {
    // TODO: implement destroy
  }
}

class _H extends BuilderNode {
  final String tagName;
  final Map<String, dynamic> props;
  final Iterable<DomNode> children;

  _H(this.tagName, this.props, this.children);

  @override
  DomBuilderElement<T> build<T>(DomBuilder<T> dom) {
    // TODO: implement build
    return null;
  }

  @override
  void destroy<T>(DomBuilderElement<T> el) {
    // TODO: implement destroy
  }
}
