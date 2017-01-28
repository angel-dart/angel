/// Service hooks to lock down user data.
library angel_security.hooks;

export 'src/hooks/add_user_to_params.dart';
export 'src/hooks/associate_current_user.dart';
export 'src/hooks/hash_password.dart';
export 'src/hooks/is_server_side.dart';
export 'src/hooks/query_with_current_user.dart';
export 'src/hooks/resrict_to_authenticated.dart';
export 'src/hooks/restrict_to_owner.dart';
export 'src/hooks/variant_permission.dart';
