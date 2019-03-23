import 'dom_node.dart';

abstract class Component<State> {
  State state;

  DomNode render();

  void afterMount() {}

  void beforeDestroy() {}

  void setState(State newState) {
    // TODO:
  }
}
