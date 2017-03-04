import 'package:code_builder/code_builder.dart';

class ServiceGenerator {
  final String name;

  const ServiceGenerator(this.name);

  bool get createsModel => true;
  bool get createsValidator => true;
  bool get exportedInServiceLibrary => true;
  bool get injectsSingleton => false;
  bool get shouldRunBuild => false;

  void applyToLibrary(LibraryBuilder library, String name, String lower) {}

  void beforeService(MethodBuilder methodBuilder, String name, String lower) {}

  void applyToConfigureServer(
      MethodBuilder configureServer, String name, String lower) {}

  ExpressionBuilder createInstance(
          MethodBuilder methodBuilder, String name, String lower) =>
      literal(null);
}
