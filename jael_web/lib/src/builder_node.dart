import 'dom_builder.dart';
import 'dom_node.dart';

abstract class BuilderNode extends DomNode {
  DomBuilderElement<T> build<T>(DomBuilder<T> dom);

  void destroy<T>(DomBuilderElement<T> el);
}
