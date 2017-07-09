import 'dart:async';
import 'dart:mirrors';
import 'package:angel_framework/angel_framework.dart';
import 'plural.dart' as pluralize;
import 'no_service.dart';

/// Represents a relationship in which the current [service] "belongs to"
/// a single member of the service at [servicePath]. Use [as] to set the name
/// on the target object.
///
/// Defaults:
/// * [localKey]: `userId`
/// * [foreignKey]: `id`
HookedServiceEventListener belongsTo(Pattern servicePath,
    {String as,
    String foreignKey,
    String localKey,
    getForeignKey(obj),
    assignForeignObject(foreign, obj)}) {
  String localId = localKey;
  var foreignName =
      as?.isNotEmpty == true ? as : pluralize.singular(servicePath.toString());

  if (localId == null) {
    localId = foreignName + 'Id';
    // print('No local key provided for belongsTo, defaulting to \'$localId\'.');
  }

  return (HookedServiceEvent e) async {
    var ref = e.service.app.service(servicePath);
    if (ref == null) throw noService(servicePath);

    _getForeignKey(obj) {
      if (getForeignKey != null)
        return getForeignKey(obj);
      else if (obj is Map)
        return obj[localId];
      else if (obj is Extensible)
        return obj.properties[localId];
      else if (localId == null || localId == 'userId')
        return obj.userId;
      else
        return reflect(obj).getField(new Symbol(localId)).reflectee;
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
        var id = await _getForeignKey(obj);
        var indexed = await ref.index({
          'query': {foreignKey ?? 'id': id}
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
