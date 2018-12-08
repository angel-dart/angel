library angel_orm_generator.test.models.user;

import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:collection/collection.dart';
import 'role.dart';
part 'user.g.dart';

@serializable
@orm
class _User extends Model {
  String username, password, email;

  // TODO: Belongs to many
  //@belongsToMany
  //List<Role> roles;
}
