import 'dart:io';

void main() {
  process(File('tool/templates/README.md'), File('README.md'));

  Directory('tool/templates/documentation').listSync().forEach((file) {
    if (file.path.endsWith('.md')) {
      var name = file.path.split(Platform.pathSeparator).last;
      process(file as File, File('documentation/$name'));
    }
  });
}

void process(File file, File to) {
  var lines = file.readAsLinesSync();

  lines = codeMacro(lines);

  to.writeAsStringSync(lines.join('\n'));
}

List<String> codeMacro(List<String> lines) {
  final result = <String>[];

  for (var line in lines) {
    if (line.trim().startsWith('@code')) {
      var path = line.substring(line.indexOf('@code') + '@code'.length).trim();
      var file = File(path);
      var extension =
          file.path.substring(file.path.lastIndexOf('.') + '.'.length);
      var code = file.readAsStringSync().trim().split('\n');

      result.add('```$extension');
      result.addAll(code);
      result.add('```');
    } else {
      result.add(line);
    }
  }

  return result;
}
