import 'package:code_builder/code_builder.dart';
import '../make/maker.dart';

class ServiceGenerator {
  final String name;

  const ServiceGenerator(this.name);

  List<MakerDependency> get dependencies => [];

  @deprecated
  bool get createsModel => true;

  @deprecated
  bool get createsValidator => true;

  @deprecated
  bool get exportedInServiceLibrary => true;

  @deprecated
  bool get injectsSingleton => false;

  @deprecated
  bool get shouldRunBuild => false;

  bool get goesFirst => false;

  void applyToLibrary(LibraryBuilder library, String name, String lower) {}

  void beforeService(LibraryBuilder library, BlockBuilder builder, String name,
      String lower) {}

  void applyToConfigureServer(
      LibraryBuilder library,
      MethodBuilder configureServer,
      BlockBuilder block,
      String name,
      String lower) {}

  Expression createInstance(LibraryBuilder library, MethodBuilder methodBuilder,
          String name, String lower) =>
      literal(null);

  @override
  String toString() => name;
}
