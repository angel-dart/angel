import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:path/path.dart' as p;
import '../../util.dart';

class NginxCommand extends Command {
  @override
  String get name => 'nginx';

  @override
  String get description =>
      'Generates a NGINX configuration for a reverse proxy + static server.';

  NginxCommand() {
    argParser.addOption('out',
        abbr: 'o',
        help:
            'An optional output file to write to; otherwise prints to stdout.');
  }

  @override
  run() async {
    var webPath = p.join(p.current, 'web');
    var nginxText = '''
server {
  listen 80 default_server;
  root ${p.absolute(webPath)}; # Set to your static files directory
  
  location / {
    try_files \$uri @proxy; # Try to serve static files; fallback to proxied Angel server
  }
  
  location @proxy {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1; # Important, do not omit
  }
}
    '''
        .trim();

    if (!argResults.wasParsed('out')) {
      print(nginxText);
    } else {
      var file = new File(argResults['out'] as String);
      await file.create(recursive: true);
      await file.writeAsString(nginxText);
      print(green.wrap(
          "$checkmark Successfully generated nginx configuration in '${file.path}'."));
    }
  }
}
