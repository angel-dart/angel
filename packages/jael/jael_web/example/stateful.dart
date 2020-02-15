import 'dart:async';
import 'package:jael_web/jael_web.dart';
part 'stateful.g.dart';

void main() {}

class _AppState {
  final int ticks;

  _AppState({this.ticks});

  _AppState copyWith({int ticks}) {
    return _AppState(ticks: ticks ?? this.ticks);
  }
}

@Jael(template: '<div>Tick count: {{state.ticks}}</div>')
class StatefulApp extends Component<_AppState> with _StatefulAppJaelTemplate {
  Timer _timer;

  StatefulApp() {
    state = _AppState(ticks: 0);
    _timer = Timer.periodic(Duration(seconds: 1), (t) {
      setState(state.copyWith(ticks: t.tick));
    });
  }

  @override
  void beforeDestroy() {
    _timer.cancel();
  }
}
