part of angel_framework.http;

class Route {
  Pattern matcher;
  String method;

  Route(String method, Pattern path, [List handlers]) {
    this.method = method;
    if (path is RegExp) this.matcher = path;
    else this.matcher = new RegExp('^' +
        path.toString().replaceAll(new RegExp('\/'), r'\/').replaceAll(
            new RegExp(':[a-zA-Z_]+'), '([^\/]+)') + r'$');
  }
}
