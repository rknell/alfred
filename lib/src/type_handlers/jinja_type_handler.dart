import 'package:jinja/jinja.dart';
import 'dart:io' as io;
import 'package:alfred/alfred.dart';
import 'package:jinja/loaders.dart';

TypeHandler jinjaTypeHandler(String viewsDirectory,
    {Map<String, Object?>? globals}) {
  var path = io.Directory.current.uri.resolve(viewsDirectory).toFilePath();

  final env = Environment(
    globals: globals ?? {},
    autoReload: true,
    loader: FileSystemLoader(path: path),
    leftStripBlocks: true,
    trimBlocks: true,
  );

  return TypeHandler<View>(
      (HttpRequest req, HttpResponse res, View view) async {
    final template = env.getTemplate('${view.path.replaceAll('.', '/')}.jinja');

    final output = template.render(view.data);

    res.headers.contentType = io.ContentType.html;
    res.write(output);
    return res.close();
  });
}

class View {
  final String path;
  final Map<String, dynamic> data;

  View(this.path, [this.data = const <String, dynamic>{}]);
}
