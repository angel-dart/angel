import 'builder_node.dart';
import 'dom_node.dart';

Map<String, dynamic> _apply(Iterable<Map<String, dynamic>> props,
    [Map<String, dynamic> attrs]) {
  var map = {};
  attrs?.forEach((k, attr) {
    if (attr is String && attr?.isNotEmpty == true) {
      map[k] = attr;
    } else if (attr is Iterable && attr?.isNotEmpty == true) {
      map[k] = attr.toList();
    } else if (attr != null) {
      map[k] = attr;
    }
  });

  for (var p in props) {
    map.addAll(p ?? {});
  }

  return map.cast<String, dynamic>();
}

DomNode a(
        {String href,
        String rel,
        String target,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'a',
        _apply([
          p,
          props
        ], {
          'href': href,
          'rel': rel,
          'target': target,
          'id': id,
          'class': className,
          'style': style,
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode abbr(
        {String title,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'addr',
        _apply([p, props],
            {'title': title, 'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode address(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'address',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode area(
        {String alt,
        Iterable<num> coordinates,
        String download,
        String href,
        String hreflang,
        String media,
        String nohref,
        String rel,
        String shape,
        String target,
        String type,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {}}) =>
    h(
        'area',
        _apply([
          p,
          props
        ], {
          'alt': alt,
          'coordinates': coordinates,
          'download': download,
          'href': href,
          'hreflang': hreflang,
          'media': media,
          'nohref': nohref,
          'rel': rel,
          'shape': shape,
          'target': target,
          'type': type,
          'id': id,
          'class': className,
          'style': style
        }));

DomNode article(
        {className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('article', _apply([p, props], {'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode aside(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'aside',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode audio(
        {bool autoplay,
        bool controls,
        bool loop,
        bool muted,
        String preload,
        String src,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'audio',
        _apply([
          p,
          props
        ], {
          'autoplay': autoplay,
          'controls': controls,
          'loop': loop,
          'muted': muted,
          'preload': preload,
          'src': src,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode b(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('b', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode base(
        {String href,
        String target,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {}}) =>
    h(
        'base',
        _apply([
          p,
          props
        ], {
          'href': href,
          'target': target,
          'id': id,
          'class': className,
          'style': style
        }));

DomNode bdi(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('bdi', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode bdo(
        {String dir,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'bdo',
        _apply([p, props],
            {'dir': dir, 'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode blockquote(
        {String cite,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'blockquote',
        _apply([p, props],
            {'cite': cite, 'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode body(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'body',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode br() => h('br');

DomNode button(
        {bool autofocus,
        bool disabled,
        form,
        String formaction,
        String formenctype,
        String formmethod,
        bool formnovalidate,
        String formtarget,
        String name,
        String type,
        String value,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'button',
        _apply([
          p,
          props
        ], {
          'autofocus': autofocus,
          'disabled': disabled,
          'form': form,
          'formaction': formaction,
          'formenctype': formenctype,
          'formmethod': formmethod,
          'formnovalidate': formnovalidate,
          'formtarget': formtarget,
          'name': name,
          'type': type,
          'value': value,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode canvas(
        {num height,
        num width,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'canvas',
        _apply([
          p,
          props
        ], {
          'height': height,
          'width': width,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode cite(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'cite',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode caption(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'caption',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode code(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'code',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode col(
        {num span,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'col',
        _apply([p, props],
            {'span': span, 'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode colgroup(
        {num span,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'colgroup',
        _apply([p, props],
            {'span': span, 'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode datalist(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'datalist',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode dd(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('dd', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode del(
        {String cite,
        String datetime,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'del',
        _apply([
          p,
          props
        ], {
          'cite': cite,
          'datetime': datetime,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode details(
        {bool open,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'details',
        _apply([p, props],
            {'open': open, 'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode dfn(
        {String title,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'dfn',
        _apply([p, props],
            {'title': title, 'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode dialog(
        {bool open,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'dialog',
        _apply([p, props],
            {'open': open, 'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode div(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('div', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode dl(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('dl', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode dt(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('dt', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode em(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('em', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode embed(
        {num height,
        String src,
        String type,
        num width,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {}}) =>
    h(
        'embed',
        _apply([
          p,
          props
        ], {
          'height': height,
          'src': src,
          'type': type,
          'width': width,
          'id': id,
          'class': className,
          'style': style
        }));

DomNode fieldset(
        {bool disabled,
        String form,
        String name,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'fieldset',
        _apply([
          p,
          props
        ], {
          'disabled': disabled,
          'form': form,
          'name': name,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode figcaption(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'figcaption',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode figure(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'figure',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode footer(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'footer',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode form(
        {String accept,
        String acceptCharset,
        String action,
        bool autocomplete,
        String enctype,
        String method,
        String name,
        bool novalidate,
        String target,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'form',
        _apply([
          p,
          props
        ], {
          'accept': accept,
          'accept-charset': acceptCharset,
          'action': action,
          'autocomplete':
              autocomplete != null ? (autocomplete ? 'on' : 'off') : null,
          'enctype': enctype,
          'method': method,
          'name': name,
          'novalidate': novalidate,
          'target': target,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode h1(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('h1', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode h2(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('h2', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));
DomNode h3(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('h3', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode h4(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('h4', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode h5(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('h5', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode h6(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('h6', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode head(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'head',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode header(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'header',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode hr() => h('hr');

DomNode html(
        {String manifest,
        String xmlns,
        String lang,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'html',
        _apply([
          p,
          props
        ], {
          'manifest': manifest,
          'xmlns': xmlns,
          'lang': lang,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode i(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('i', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode iframe(
        {num height,
        String name,
        sandbox,
        String src,
        String srcdoc,
        num width,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {}}) =>
    h(
        'iframe',
        _apply([
          p,
          props
        ], {
          'height': height,
          'name': name,
          'sandbox': sandbox,
          'src': src,
          'srcdoc': srcdoc,
          'width': width,
          'id': id,
          'class': className,
          'style': style
        }));

DomNode img(
        {String alt,
        String crossorigin,
        num height,
        String ismap,
        String longdesc,
        sizes,
        String src,
        String srcset,
        String usemap,
        num width,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {}}) =>
    h(
        'img',
        _apply([
          p,
          props
        ], {
          'alt': alt,
          'crossorigin': crossorigin,
          'height': height,
          'ismap': ismap,
          'longdesc': longdesc,
          'sizes': sizes,
          'src': src,
          'srcset': srcset,
          'usemap': usemap,
          'width': width,
          'id': id,
          'class': className,
          'style': style
        }));

DomNode input(
        {String accept,
        String alt,
        bool autocomplete,
        bool autofocus,
        bool checked,
        String dirname,
        bool disabled,
        String form,
        String formaction,
        String formenctype,
        String method,
        String formnovalidate,
        String formtarget,
        num height,
        String list,
        max,
        num maxlength,
        min,
        bool multiple,
        String name,
        String pattern,
        String placeholder,
        bool readonly,
        bool required,
        num size,
        String src,
        num step,
        String type,
        String value,
        num width,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {}}) =>
    h(
        'input',
        _apply([
          p,
          props
        ], {
          'accept': accept,
          'alt': alt,
          'autocomplete':
              autocomplete == null ? null : (autocomplete ? 'on' : 'off'),
          'autofocus': autofocus,
          'checked': checked,
          'dirname': dirname,
          'disabled': disabled,
          'form': form,
          'formaction': formaction,
          'formenctype': formenctype,
          'method': method,
          'formnovalidate': formnovalidate,
          'formtarget': formtarget,
          'height': height,
          'list': list,
          'max': max,
          'maxlength': maxlength,
          'min': min,
          'multiple': multiple,
          'name': name,
          'pattern': pattern,
          'placeholder': placeholder,
          'readonly': readonly,
          'required': required,
          'size': size,
          'src': src,
          'step': step,
          'type': type,
          'value': value,
          'width': width,
          'id': id,
          'class': className,
          'style': style
        }));

DomNode ins(
        {String cite,
        String datetime,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'ins',
        _apply([
          p,
          props
        ], {
          'cite': cite,
          'datetime': datetime,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode kbd(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('kbd', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode keygen(
        {bool autofocus,
        String challenge,
        bool disabled,
        String from,
        String keytype,
        String name,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'keygen',
        _apply([
          p,
          props
        ], {
          'autofocus': autofocus,
          'challenge': challenge,
          'disabled': disabled,
          'from': from,
          'keytype': keytype,
          'name': name,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode label(
        {String for_,
        String form,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'label',
        _apply([
          p,
          props
        ], {
          'for': for_,
          'form': form,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode legend(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'legend',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode li(
        {num value,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'li',
        _apply([p, props],
            {'value': value, 'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode link(
        {String crossorigin,
        String href,
        String hreflang,
        String media,
        String rel,
        sizes,
        String target,
        String type,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {}}) =>
    h(
        'link',
        _apply([
          p,
          props
        ], {
          'crossorigin': crossorigin,
          'href': href,
          'hreflang': hreflang,
          'media': media,
          'rel': rel,
          'sizes': sizes,
          'target': target,
          'type': type,
          'id': id,
          'class': className,
          'style': style
        }));

DomNode main(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'main',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode map(
        {String name,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'map',
        _apply([p, props],
            {'name': name, 'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode mark(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'mark',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode menu(
        {String label,
        String type,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'menu',
        _apply([
          p,
          props
        ], {
          'label': label,
          'type': type,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode menuitem(
        {bool checked,
        command,
        bool default_,
        bool disabled,
        String icon,
        String label,
        String radiogroup,
        String type,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'menuitem',
        _apply([
          p,
          props
        ], {
          'checked': checked,
          'command': command,
          'default': default_,
          'disabled': disabled,
          'icon': icon,
          'label': label,
          'radiogroup': radiogroup,
          'type': type,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode meta(
        {String charset,
        String content,
        String httpEquiv,
        String name,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {}}) =>
    h(
        'meta',
        _apply([
          p,
          props
        ], {
          'charset': charset,
          'content': content,
          'http-equiv': httpEquiv,
          'name': name,
          'id': id,
          'class': className,
          'style': style
        }));

DomNode nav(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('nav', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode noscript(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'noscript',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode object(
        {String data,
        String form,
        num height,
        String name,
        String type,
        String usemap,
        num width,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'object',
        _apply([
          p,
          props
        ], {
          'data': data,
          'form': form,
          'height': height,
          'name': name,
          'type': type,
          'usemap': usemap,
          'width': width,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode ol(
        {bool reversed,
        num start,
        String type,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'ol',
        _apply([
          p,
          props
        ], {
          'reversed': reversed,
          'start': start,
          'type': type,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode optgroup(
        {bool disabled,
        String label,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'optgroup',
        _apply([
          p,
          props
        ], {
          'disabled': disabled,
          'label': label,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode option(
        {bool disabled,
        String label,
        bool selected,
        String value,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'option',
        _apply([
          p,
          props
        ], {
          'disabled': disabled,
          'label': label,
          'selected': selected,
          'value': value,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode output(
        {String for_,
        String form,
        String name,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'output',
        _apply([
          p,
          props
        ], {
          'for': for_,
          'form': form,
          'name': name,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode p(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('p', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode param(
        {String name,
        value,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {}}) =>
    h(
        'param',
        _apply([
          p,
          props
        ], {
          'name': name,
          'value': value,
          'id': id,
          'class': className,
          'style': style
        }));

DomNode picture(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'picture',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode pre(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('pre', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode progress(
        {num max,
        num value,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'progress',
        _apply([
          p,
          props
        ], {
          'max': max,
          'value': value,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode q(
        {String cite,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'q',
        _apply([p, props],
            {'cite': cite, 'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode rp(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('rp', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode rt(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('rt', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode ruby(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'ruby',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode s(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('s', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode samp(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'samp',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode script(
        {bool async,
        String charset,
        bool defer,
        String src,
        String type,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'script',
        _apply([
          p,
          props
        ], {
          'async': async,
          'charset': charset,
          'defer': defer,
          'src': src,
          'type': type,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode section(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'section',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode select(
        {bool autofocus,
        bool disabled,
        String form,
        bool multiple,
        bool required,
        num size,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'select',
        _apply([
          p,
          props
        ], {
          'autofocus': autofocus,
          'disabled': disabled,
          'form': form,
          'multiple': multiple,
          'required': required,
          'size': size,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode small(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'small',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode source(
        {String src,
        String srcset,
        String media,
        sizes,
        String type,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {}}) =>
    h(
        'source',
        _apply([
          p,
          props
        ], {
          'src': src,
          'srcset': srcset,
          'media': media,
          'sizes': sizes,
          'type': type,
          'id': id,
          'class': className,
          'style': style
        }));

DomNode span(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'span',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode strong(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'strong',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode style(
        {String media,
        bool scoped,
        String type,
        String id,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'style',
        _apply([p, props],
            {'media': media, 'scoped': scoped, 'type': type, 'id': id}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode sub(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('sub', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode summary(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'summary',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode sup(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('sup', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode table(
        {bool sortable,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'table',
        _apply([
          p,
          props
        ], {
          'sortable': sortable,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode tbody(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'tbody',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode td(
        {num colspan,
        headers,
        num rowspan,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'td',
        _apply([
          p,
          props
        ], {
          'colspan': colspan,
          'headers': headers,
          'rowspan': rowspan,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode textarea(
        {bool autofocus,
        num cols,
        String dirname,
        bool disabled,
        String form,
        num maxlength,
        String name,
        String placeholder,
        bool readonly,
        bool required,
        num rows,
        String wrap,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'textarea',
        _apply([
          p,
          props
        ], {
          'autofocus': autofocus,
          'cols': cols,
          'dirname': dirname,
          'disabled': disabled,
          'form': form,
          'maxlength': maxlength,
          'name': name,
          'placeholder': placeholder,
          'readonly': readonly,
          'required': required,
          'rows': rows,
          'wrap': wrap,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode tfoot(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'tfoot',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode th(
        {String abbr,
        num colspan,
        headers,
        num rowspan,
        String scope,
        sorted,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'th',
        _apply([
          p,
          props
        ], {
          'abbr': abbr,
          'colspan': colspan,
          'headers': headers,
          'rowspan': rowspan,
          'scope': scope,
          'sorted': sorted,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode thead(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'thead',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode time(
        {String datetime,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'time',
        _apply([
          p,
          props
        ], {
          'datetime': datetime,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode title(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'title',
        _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode tr(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('tr', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode track(
        {bool default_,
        String kind,
        String label,
        String src,
        String srclang,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {}}) =>
    h(
        'track',
        _apply([
          p,
          props
        ], {
          'default': default_,
          'kind': kind,
          'label': label,
          'src': src,
          'srclang': srclang,
          'id': id,
          'class': className,
          'style': style
        }));

DomNode u(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('u', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode ul(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('ul', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode var_(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('var', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode video(
        {bool autoplay,
        bool controls,
        num height,
        bool loop,
        bool muted,
        String poster,
        String preload,
        String src,
        num width,
        String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h(
        'video',
        _apply([
          p,
          props
        ], {
          'autoplay': autoplay,
          'controls': controls,
          'height': height,
          'loop': loop,
          'muted': muted,
          'poster': poster,
          'preload': preload,
          'src': src,
          'width': width,
          'id': id,
          'class': className,
          'style': style
        }),
        []..addAll(c ?? [])..addAll(children ?? []));

DomNode wbr(
        {String id,
        className,
        style,
        Map<String, dynamic> p: const {},
        @deprecated Map<String, dynamic> props: const {},
        Iterable<DomNode> c: const [],
        @deprecated Iterable<DomNode> children: const []}) =>
    h('wbr', _apply([p, props], {'id': id, 'class': className, 'style': style}),
        []..addAll(c ?? [])..addAll(children ?? []));
