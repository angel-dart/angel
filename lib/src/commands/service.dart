import "dart:io";
import "package:args/command_runner.dart";
import "package:console/console.dart";
import "package:mustache4dart/mustache4dart.dart";

class ServiceCommand extends Command {
  final String CUSTOM = "Custom";
  final String MEMORY = "In-Memory";
  final String MONGO = "MongoDB";
  final String MONGO_TYPED = "MongoDB (typed)";
  final String TRESTLE = "Trestle";
  final TextPen _pen = new TextPen();

  @override String get name => "service";

  @override String get description =>
      "Creates a new service within the given project.";

  @override
  run() async {
    var name = await readInput("Name of Service (not plural): ");
    var chooser = new Chooser([TRESTLE, MONGO, MONGO_TYPED, MEMORY, CUSTOM],
        message: "What type of service would you like to create? ");
    var type = await chooser.choose();

    fail() {
      _pen.red();
      _pen("Could not successfully create service $name.");
      _pen();
    }

    String serviceSource = "";

    if (type == MONGO) {
      serviceSource = _generateMongoService(name);
    } else if (type == MONGO_TYPED) {
      _pen.blue();
      _pen("${Icon.STAR} To create a typed Mongo service, please create a schema using 'angel schema'.");
      _pen();
    } else if (type == MEMORY) {
      serviceSource = _generateMemoryService(name);
    } else if (type == CUSTOM) {
      serviceSource = _generateCustomService(name);
    } else if (type == TRESTLE) {
      _pen.blue();
      _pen("${Icon.STAR} Trestle services are not yet implemented. :(");
      _pen();
    } else {
      print("Code to generate a $type service is not yet written.");
    }

    if (serviceSource.isEmpty) {
      if (type == MONGO_TYPED)
        return;

      fail();
      throw new Exception("Empty generated service code.");
    }

    var servicesDir = new Directory("lib/src/services");
    var serviceFile = new File.fromUri(servicesDir.uri.resolve("${name.toLowerCase()}.dart"));
    var serviceLibrary = new File.fromUri(
        servicesDir.uri.resolve("services.dart"));

    if (!await servicesDir.exists())
      await servicesDir.create(recursive: true);

    await serviceFile.writeAsString(serviceSource);
    await serviceLibrary.writeAsString(
        "\nexport '${name.toLowerCase()}.dart';", mode: FileMode.APPEND);

    _pen.green();
    _pen("${Icon.CHECKMARK} Successfully generated service $name.");
    _pen();
  }

  _generateCustomService(String name) {
    return '''
import 'package:angel_framework/angel_framework.dart';

class ${name}Service extends Service {
  ${name}Service():super() {
    // Your logic here!
  }
}
    '''.trim();
  }

  _generateMemoryService(String name) {
    return '''
import 'package:angel_framework/defs.dart';
import 'package:angel_framework/angel_framework.dart';

/// Store in-memory instances of this class.
class $name extends MemoryModel {
}

/// Manages [$name] in-memory.
class ${name}Service extends MemoryService<$name> {
  ${name}Service():super() {
    // Your logic here!
  }
}
    '''.trim();
  }

  _generateMongoService(String name) {
    return '''
import 'package:angel_mongo/angel_mongo.dart';

class ${name}Service extends MongoService {
  ${name}Service(collection):super(collection) {
    // Your logic here!
  }
}
    '''.trim();
  }
}