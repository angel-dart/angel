import "package:args/command_runner.dart";
import "package:console/console.dart";
import "package:mustache4dart/mustache4dart.dart";

class ServiceCommand extends Command {
  final String CUSTOM = "Custom";
  final String MEMORY = "In-Memory";
  final String MONGO = "MongoDB";
  final TextPen _pen = new TextPen();

  @override String get name => "service";

  @override String get description =>
      "Creates a new service within the given project.";

  @override
  run() async {
    var name = await readInput("Name of Service (not plural): ");
    var chooser = new Chooser([MONGO, MEMORY, CUSTOM],
        message: "What type of service would you like to create? ");
    var type = await chooser.choose();
    print("Creating $type service $name");

    fail() {
      _pen.red();
      _pen("Could not successfully create service $name.");
      _pen();
    }

    String serviceSource = "";

    if (type == MONGO) {
      serviceSource = _generateMongoService(name);
    } else fail();

    print("Generated source: ");
    print(serviceSource);
  }

  _generateMongoService(String name) {
    return '''
    import "package:angel_mongo/angel_mongo.dart";

    class ${name}Service extends MongoService {
      ${name}Service(collection):super(collection) {
        print("YEET");
      }
    }
    ''';
  }
}