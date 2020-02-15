import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:logging/logging.dart';

main() async {
  // Logging set up/boilerplate
  Logger.root.onRecord.listen(print);

  // Create our server.
  var app = Angel(logger: Logger('angel'), reflector: MirrorsReflector());
  var http = AngelHttp(app);

  await app.mountController<ArtistsController>();

  // Simple fallback to throw a 404 on unknown paths.
  app.fallback((req, res) {
    throw AngelHttpException.notFound(
      message: 'Unknown path: "${req.uri.path}"',
    );
  });

  app.errorHandler = (e, req, res) => e.toJson();

  await http.startServer('127.0.0.1', 3000);
  print('Listening at ${http.uri}');
  app.dumpTree();
}

class ArtistsController extends Controller {
  List index() {
    return ['Elvis', 'Stevie', 'Van Gogh'];
  }

  String getById(int id, RequestContext req) {
    return 'You fetched ID: $id from IP: ${req.ip}';
  }

  @Expose.post
  form(RequestContext req) async {
    // Deserialize the body into an artist.
    var artist = await req.deserializeBody((m) {
      return Artist(name: m['name'] as String ?? '(unknown name)');
    });

    // Return it (it will be serialized to JSON).
    return artist;
  }
}

class Artist {
  final String name;

  Artist({this.name});

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}
