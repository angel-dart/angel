import 'dart:async';
import 'dart:mirrors';
import 'package:angel_framework/angel_framework.dart';
import 'plural.dart' as pluralize;
import 'no_service.dart';

/// Represents a relationship in which the current [service] "owns"
/// a single member of the service at [servicePath]. Use [as] to set the name
/// on the target object.
///
/// Defaults:
/// * [foreignKey]: `userId`
/// * [localKey]: `id`
HookedServiceEventListener hasOne(Pattern servicePath,
    {String as,
    String foreignKey,
    String localKey,
    getLocalKey(obj),
    assignForeignObject(foreign, obj)}) {

  return (HookedServiceEvent e) async {
    var ref = e.service.app.service(servicePath);
    var foreignName = as?.isNotEmpty == true
        ? as
        : pluralize.singular(servicePath.toString());
    if (ref == null) throw noService(servicePath);

    _getLocalKey(obj) {
      if (getLocalKey != null)
        return getLocalKey(obj);
      else if (obj is Map)
        return obj[localKey ?? 'id'];
      else if (obj is Extensible)
        return obj.properties[localKey ?? 'id'];
      else if (localKey == null || localKey == 'id')
        return obj.id;
      else
        return reflect(obj).getField(new Symbol(localKey ?? 'id')).reflectee;
    }

    _assignForeignObject(foreign, obj) {
      if (assignForeignObject != null)
        return assignForeignObject(foreign, obj);
      else if (obj is Map)
        obj[foreignName] = foreign;
      else if (obj is Extensible)
        obj.properties[foreignName] = foreign;
      else
        reflect(obj).setField(new Symbol(foreignName), foreign);
    }

    _normalize(obj) async {
      if (obj != null) {
        var id = await _getLocalKey(obj);

        var indexed = await ref.index({
          'query': {foreignKey ?? 'userId': id}
        });

        if (indexed == null || indexed is! List || indexed.isNotEmpty != true) {
          await _assignForeignObject(null, obj);
        } else {
          var child = indexed.first;
          await _assignForeignObject(child, obj);
        }
      }
    }

    if (e.result is Iterable) {
      await Future.wait(e.result.map(_normalize));
    } else
      await _normalize(e.result);
  };
}
