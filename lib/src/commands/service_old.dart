import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:console/console.dart';
import 'package:id/id.dart';
import 'package:recase/recase.dart';
import 'init.dart' show preBuild;

class ServiceCommand extends Command {
  final String CUSTOM = 'Custom';
  final String MEMORY = 'In-Memory';
  final String MEMORY_JSON = 'In-Memory (serialized via `source_gen`)';
  final String MONGO = 'MongoDB';
  final String MONGO_TYPED = 'MongoDB (typed)';
  final String MONGO_TYPED_JSON =
      'MongoDB (typed, serialized via `source_gen`)';
  final String TRESTLE = 'Trestle';
  final TextPen _pen = new TextPen();

  @override
  String get name => 'service';

  @override
  String get description => 'Creates a new service within the given project.';

  String _snake(name) => idFromString(name).snake;

  @override
  run() async {
    var name = await readInput('Name of Service (not plural): ');
    var chooser = new Chooser([MONGO, MONGO_TYPED, MEMORY, CUSTOM],
        message: 'What type of service would you like to create? ');
    var type = await chooser.choose();

    fail() {
      _pen.red();
      _pen('Could not successfully create service $name.');
      _pen();
    }

    String serviceSource = '';

    if (type == MONGO) {
      serviceSource = _generateMongoService(name);
    } else if (type == MONGO_TYPED) {
      serviceSource = _generateMongoTypedService(name);
      await _generateMongoModel(name);
      await _generateValidator(name);
    } else if (type == MONGO_TYPED_JSON) {
      serviceSource = _generateMongoTypedService(name);
      await _generateMongoModelJson(name);
      await _generateValidator(name);
    } else if (type == MEMORY) {
      serviceSource = _generateMemoryService(name);
      await _generateMemoryModel(name);
      await _generateValidator(name);
    } else if (type == MEMORY_JSON) {
      serviceSource = _generateMemoryService(name);
      await _generateMemoryModelJson(name);
      await _generateValidator(name);
    } else if (type == CUSTOM) {
      serviceSource = _generateCustomService(name);
    } else if (type == TRESTLE) {
      _pen.blue();
      _pen('${Icon.STAR} Trestle services are not yet implemented. :(');
      _pen();
    } else {
      print('Code to generate a $type service is not yet written.');
    }

    if (serviceSource.isEmpty) {
      fail();
      throw new Exception('Empty generated service code.');
    }

    var lower = _snake(name);
    var servicesDir = new Directory('lib/src/services');
    var serviceFile = new File.fromUri(servicesDir.uri.resolve('$lower.dart'));
    var testDir = new Directory('test/services');
    var testFile = new File.fromUri(testDir.uri.resolve('${lower}_test.dart'));

    if (!await servicesDir.exists()) await servicesDir.create(recursive: true);

    if (!await testDir.exists()) await testDir.create(recursive: true);

    await serviceFile.writeAsString(serviceSource);

    if (type == MONGO_TYPED || type == MEMORY) {
      var serviceLibrary = new File('lib/src/models/models.dart');
      await serviceLibrary.writeAsString("\nexport '$lower.dart';",
          mode: FileMode.APPEND);
      await preBuild(Directory.current);
    }

    await testFile.writeAsString(_generateTests(name, type));

    var runConfig = new File('./.idea/runConfigurations/${name}_Tests.xml');

    if (!await runConfig.exists()) {
      await runConfig.create(recursive: true);
      await runConfig.writeAsString(_generateRunConfiguration(name));
    }

    _pen.green();
    _pen('${Icon.CHECKMARK} Successfully generated service $name.');
    _pen();
  }

  _generateValidator(String name) async {
    var rc = new ReCase(name);
    var file = new File('lib/src/validators/${rc.snakeCase}.dart');

    if (!await file.exists()) await file.createSync(recursive: true);

    await file.writeAsString('''
import 'package:angel_validate/angel_validate.dart';

final Validator CREATE_${rc.constantCase} =
    new Validator({'name*': isString, 'desc*': isString});
    '''
        .trim());
  }

  _generateCustomService(String name) {
    return '''
import 'package:angel_framework/angel_framework.dart';

class ${name}Service extends Service {
  ${name}Service():super() {
    // Your logic here!
  }
}
    '''
        .trim();
  }

  _generateMemoryModel(String name) async {
    var lower = _snake(name);
    var file = new File('lib/src/models/$lower.dart');

    if (!await file.exists()) await file.createSync(recursive: true);

    await file.writeAsString('''
library angel.models.$lower;

import 'package:angel_framework/common.dart';

class $name extends Model {
  String name, desc;

  $name({String id, this.name, this.desc}) {
    this.id = id;
  }
}
    '''
        .trim());
  }

  _generateMemoryModelJson(String name) async {
    var lower = _snake(name);
    var file = new File('lib/src/models/$lower.dart');

    if (!await file.exists()) await file.createSync(recursive: true);

    await file.writeAsString('''
library angel.models.$lower;

import 'package:angel_framework/common.dart';
import 'package:source_gen/generators/json_serializable.dart';

part '$lower.g.dart';

@JsonSerializable()
class $name extends Model with _\$${name}SerializerMixin {
  @JsonKey('id')
  @override
  String id;

  @JsonKey('name')
  String name;
  
  @JsonKey('desc')
  String desc;

  factory $name.fromJson(Map json) => _\$${name}FromJson(json);

  $name({this.id, this.name, this.desc});
}
    '''
        .trim());
  }

  _generateMemoryService(String name) {
    var rc = new ReCase(name);
    var lower = rc.snakeCase;

    return '''
import 'package:angel_framework/angel_framework.dart';
import '../models/$lower.dart';
export '../models/$lower.dart';

/// Manages [$name] in-memory.
class ${name}Service extends MemoryService<$name> {
  ${name}Service():super() {
    // Your logic here!
  }
}
    '''
        .trim();
  }

  _generateMongoModel(String name) async {
    var lower = _snake(name);
    var file = new File('lib/src/models/$lower.dart');

    if (!await file.exists()) await file.createSync(recursive: true);

    await file.writeAsString('''
library angel.models.$lower;

import 'package:angel_mongo/model.dart';
import 'package:source_gen/generators/json_serializable.dart';

part '$lower.g.dart';

@JsonSerializable()
class $name extends Model with _\$${name}SerializerMixin {
  @JsonKey('id')
  @override
  String id;

  @JsonKey('name')
  String name;
  
  @JsonKey('desc')
  String desc;

  factory $name.fromJson(Map json) => _\$${name}FromJson(json);

  $name({this.id, this.name, this.desc});
}
    '''
        .trim());
  }

  _generateMongoModelJson(String name) async {
    var lower = _snake(name);
    var file = new File('lib/src/models/$lower.dart');

    if (!await file.exists()) await file.createSync(recursive: true);

    await file.writeAsString('''
library angel.models.$lower;

import 'package:angel_framework/common.dart';
import 'package:source_gen/generators/json_serializable.dart';

part '$lower.g.dart';

@JsonSerializable()
class $name extends Model with _\$${name}SerializerMixin {
  @JsonKey('id')
  @override
  String id;

  @JsonKey('name')
  String name;
  
  @JsonKey('desc')
  String desc;

  factory $name.fromJson(Map json) => _\$${name}FromJson(json);

  $name({this.id, this.name, this.desc});
}
    '''
        .trim());
  }

  _generateMongoService(String name) {
    var lower = _snake(name);

    return '''
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mongo/angel_mongo.dart';
import 'package:angel_validate/angel_validate.dart';
import 'package:angel_validate/server.dart';
import 'package:mongo_dart/mongo_dart.dart';

final Validator ${lower}Schema = new Validator({
  'name*': [isString, isNotEmpty],
  'desc*': [isString, isNotEmpty]
});

configureServer(Db db) {
  return (Angel app) async {
    app.use('/api/${lower}s', new ${name}Service(db.collection('${lower}s')));

    HookedService service = app.service('api/${lower}s');
    app.container.singleton(service.inner);

    service
      ..beforeCreate.listen(validateEvent(${lower}Schema))
      ..beforeUpdate.listen(validateEvent(${lower}Schema));
  };
}

/// Manages [$name] in the database.
class ${name}Service extends MongoService {
  ${name}Service(collection):super(collection) {
    // Your logic here!
  }
}
    '''
        .trim();
  }

  _generateMongoTypedService(String name) {
    var lower = _snake(name);

    return '''
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mongo/angel_mongo.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/$lower.dart';
export '../models/$lower.dart';

configureServer(Db db) {
  return (Angel app) async {
    app.use('/api/${lower}s', new ${name}Service(db.collection('${lower}s')));

    HookedService service = app.service('api/${lower}s');
    app.container.singleton(service.inner);
  };
}

/// Manages [$name] in the database.
class ${name}Service extends MongoTypedService<$name> {
  ${name}Service(collection):super(collection) {
    // Your logic here!
  }
}
    '''
        .trim();
  }

  _generateRunConfiguration(String name) {
    var lower = _snake(name);

    return '''
    <component name="ProjectRunConfigurationManager">
      <configuration default="false" name="$name Tests" type="DartTestRunConfigurationType" factoryName="Dart Test" singleton="true">
        <option name="filePath" value="\$PROJECT_DIR\$/test/services/${lower}_test.dart" />
        <method />
      </configuration>
    </component>
'''
        .trim();
  }

  _generateTests(String name, String type) {
    var lower = _snake(name);

    return '''
import 'dart:io';
import 'package:angel/angel.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

main() async {
  Angel app;
  TestClient client;

  setUp(() async {
    app = await createServer();
    client = await connectTo(app);
  });

  tearDown(() async {
    await client.close();
    app = null;
  });

  test('index via REST', () async {
    var response = await client.get('/api/${lower}s');
    expect(response, hasStatus(HttpStatus.OK));
  });

  test('Index ${lower}s', () async {
    var ${lower}s = await client.service('api/${lower}s').index();
    print(${lower}s);
  });
}

    '''
        .trim();
  }
}
