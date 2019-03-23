import 'package:jael_web/jael_web.dart';
import 'package:jael_web/elements.dart';
part 'main.g.dart';

@Jael(template: '''
<div>
  <h1>Hello, Jael!</h1>
  <i>Current time: {{now}}</i>
</div>
''')
class Hello extends Component with _HelloJaelTemplate {
  DateTime get now => DateTime.now();
}

// Could also have been:
class Hello2 extends Component {
  DateTime get now => DateTime.now();

  @override
  DomNode render() {
    return div(c: [
      h1(c: [
        text('Hello, Jael!'),
      ]),
      i(c: [
        text('Current time: $now'),
      ]),
    ]);
  }
}
