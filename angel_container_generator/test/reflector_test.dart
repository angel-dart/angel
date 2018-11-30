import 'package:angel_container/angel_container.dart';
import 'package:angel_container_generator/angel_container_generator.dart';
import 'package:test/test.dart';
import 'reflector_test.reflectable.dart';

void main() {
  initializeReflectable();
  var artist = new Artist();
  var reflector = const GeneratedReflector();
  Container container;

  setUp(() {
    container = new Container(reflector);
    container.registerSingleton(artist);
    //container.registerSingleton(new Artist(name: 'Tobe Osakwe'));
  });

  group('reflectClass', () {
    var mirror = reflector.reflectClass(Artist);

    test('name', () {
      expect(mirror.name, 'Artist');
    });
  });

  test('inject constructor parameters', () {
    var album = container.make<Album>();
    print(album.title);
    expect(album.title, 'flowers by ${artist.lowerName}');
  });
}

@contained
class Artist {
  //final String name;

  //Artist({this.name});

  String get lowerName {
    //return name.toLowerCase();
    return hashCode.toString().toLowerCase();
  }
}

@contained
class Album {
  final Artist artist;

  Album(this.artist);

  String get title => 'flowers by ${artist.lowerName}';
}
