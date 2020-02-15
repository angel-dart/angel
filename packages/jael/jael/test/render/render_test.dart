import 'package:code_buffer/code_buffer.dart';
import 'package:jael/jael.dart' as jael;
import 'package:symbol_table/symbol_table.dart';
import 'package:test/test.dart';

main() {
  test('attribute binding', () {
    const template = '''
<html>
  <body>
    <h1>Hello</h1>
    <img ready="always" data-img-src=profile['avatar'] />
    <input name="csrf_token" type="hidden" value=csrf_token>
  </body>
</html>
''';

    var buf = CodeBuffer();
    jael.Document document;
    SymbolTable scope;

    try {
      document = jael.parseDocument(template, sourceUrl: 'test.jael');
      scope = SymbolTable<dynamic>(values: {
        'csrf_token': 'foo',
        'profile': {
          'avatar': 'thosakwe.png',
        }
      });
    } on jael.JaelError catch (e) {
      print(e);
      print(e.stackTrace);
    }

    expect(document, isNotNull);
    const jael.Renderer().render(document, buf, scope);
    print(buf);

    expect(
        buf.toString(),
        '''
<html>
  <body>
    <h1>
      Hello
    </h1>
    <img ready="always" data-img-src="thosakwe.png">
    <input name="csrf_token" type="hidden" value="foo">
  </body>
</html>
    '''
            .trim());
  });

  test('interpolation', () {
    const template = '''
<!doctype HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
  <body>
    <h1>Pokémon</h1>
    {{ pokemon.name }} - {{ pokemon.type }}
    <img>
  </body>
</html>
''';

    var buf = CodeBuffer();
    //jael.scan(template, sourceUrl: 'test.jael').tokens.forEach(print);
    var document = jael.parseDocument(template, sourceUrl: 'test.jael');
    var scope = SymbolTable<dynamic>(values: {
      'pokemon': const _Pokemon('Darkrai', 'Dark'),
    });

    const jael.Renderer().render(document, buf, scope);
    print(buf);

    expect(
        buf.toString().replaceAll('\n', '').replaceAll(' ', '').trim(),
        '''
<!doctype HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
  <body>
    <h1>
      Pokémon
    </h1>
    Darkrai - Dark
    <img/>
  </body>
</html>
    '''
            .replaceAll('\n', '')
            .replaceAll(' ', '')
            .trim());
  });

  test('for loop', () {
    const template = '''
<html>
  <body>
    <h1>Pokémon</h1>
    <ul>
      <li for-each=starters as="starter" index-as="idx">#{{ idx }} {{ starter.name }} - {{ starter.type }}</li>
    </ul>
  </body>
</html>
''';

    var buf = CodeBuffer();
    var document = jael.parseDocument(template, sourceUrl: 'test.jael');
    var scope = SymbolTable<dynamic>(values: {
      'starters': starters,
    });

    const jael.Renderer().render(document, buf, scope);
    print(buf);

    expect(
        buf.toString(),
        '''
<html>
  <body>
    <h1>
      Pokémon
    </h1>
    <ul>
      <li>
        #0 Bulbasaur - Grass
      </li>
      <li>
        #1 Charmander - Fire
      </li>
      <li>
        #2 Squirtle - Water
      </li>
    </ul>
  </body>
</html>
    '''
            .trim());
  });

  test('conditional', () {
    const template = '''
<html>
  <body>
    <h1>Conditional</h1>
    <b if=starters.isEmpty>Empty</b>
    <b if=starters.isNotEmpty>Not empty</b>
  </body>
</html>
''';

    var buf = CodeBuffer();
    var document = jael.parseDocument(template, sourceUrl: 'test.jael');
    var scope = SymbolTable<dynamic>(values: {
      'starters': starters,
    });

    const jael.Renderer().render(document, buf, scope);
    print(buf);

    expect(
        buf.toString(),
        '''
<html>
  <body>
    <h1>
      Conditional
    </h1>
    <b>
      Not empty
    </b>
  </body>
</html>  
    '''
            .trim());
  });

  test('declare', () {
    const template = '''
<div>
 <declare one=1 two=2 three=3>
   <ul>
    <li>{{one}}</li>
    <li>{{two}}</li>
    <li>{{three}}</li>
   </ul>
   <ul>
    <declare three=4>
      <li>{{one}}</li>
      <li>{{two}}</li>
      <li>{{three}}</li>
    </declare>
   </ul>
 </declare>
</div>
''';

    var buf = CodeBuffer();
    var document = jael.parseDocument(template, sourceUrl: 'test.jael');
    var scope = SymbolTable();

    const jael.Renderer().render(document, buf, scope);
    print(buf);

    expect(
        buf.toString(),
        '''
<div>
  <ul>
    <li>
      1
    </li>
    <li>
      2
    </li>
    <li>
      3
    </li>
  </ul>
  <ul>
    <li>
      1
    </li>
    <li>
      2
    </li>
    <li>
      4
    </li>
  </ul>
</div>
'''
            .trim());
  });

  test('unescaped attr/interp', () {
    const template = '''
<div>
  <img src!="<SCARY XSS>" />
  {{- "<MORE SCARY XSS>" }}
</div>
''';

    var buf = CodeBuffer();
    var document = jael.parseDocument(template, sourceUrl: 'test.jael');
    var scope = SymbolTable();

    const jael.Renderer().render(document, buf, scope);
    print(buf);

    expect(
        buf.toString().replaceAll('\n', '').replaceAll(' ', '').trim(),
        '''
<div>
  <img src="<SCARY XSS>">
  <MORE SCARY XSS>
</div>
'''
            .replaceAll('\n', '')
            .replaceAll(' ', '')
            .trim());
  });

  test('quoted attribute name', () {
    const template = '''
<button '(click)'="myEventHandler(\$event)"></button>
''';

    var buf = CodeBuffer();
    var document = jael.parseDocument(template, sourceUrl: 'test.jael');
    var scope = SymbolTable();

    const jael.Renderer().render(document, buf, scope);
    print(buf);

    expect(
        buf.toString(),
        '''
<button (click)="myEventHandler(\$event)">
</button>
'''
            .trim());
  });

  test('switch', () {
    const template = '''
<switch value=account.isDisabled>
  <case value=true>
    BAN HAMMER LOLOL
  </case>
  <case value=false>
    You are in good standing.
  </case>
  <default>
    Weird...
  </default>
</switch>
''';

    var buf = CodeBuffer();
    var document = jael.parseDocument(template, sourceUrl: 'test.jael');
    var scope = SymbolTable<dynamic>(values: {
      'account': _Account(isDisabled: true),
    });

    const jael.Renderer().render(document, buf, scope);
    print(buf);

    expect(buf.toString().trim(), 'BAN HAMMER LOLOL');
  });

  test('default', () {
    const template = '''
<switch value=account.isDisabled>
  <case value=true>
    BAN HAMMER LOLOL
  </case>
  <case value=false>
    You are in good standing.
  </case>
  <default>
    Weird...
  </default>
</switch>
''';

    var buf = CodeBuffer();
    var document = jael.parseDocument(template, sourceUrl: 'test.jael');
    var scope = SymbolTable<dynamic>(values: {
      'account': _Account(isDisabled: null),
    });

    const jael.Renderer().render(document, buf, scope);
    print(buf);

    expect(buf.toString().trim(), 'Weird...');
  });
}

const List<_Pokemon> starters = [
  _Pokemon('Bulbasaur', 'Grass'),
  _Pokemon('Charmander', 'Fire'),
  _Pokemon('Squirtle', 'Water'),
];

class _Pokemon {
  final String name, type;

  const _Pokemon(this.name, this.type);
}

class _Account {
  final bool isDisabled;

  _Account({this.isDisabled});
}
