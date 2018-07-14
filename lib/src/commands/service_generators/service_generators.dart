import 'custom.dart';
import 'file_service.dart';
import 'generator.dart';
import 'map.dart';
import 'mongo.dart';
import 'rethink.dart';
export 'generator.dart';

const List<ServiceGenerator> serviceGenerators = const [
  const MapServiceGenerator(),
  const FileServiceGenerator(),
  const MongoServiceGenerator(),
  const RethinkServiceGenerator(),
  const CustomServiceGenerator()
];
