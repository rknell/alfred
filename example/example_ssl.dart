import 'dart:io';

import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  app.get('/html', (req, res) {
    res.headers.contentType = ContentType.html;
    return '<html><body><h1>Title!</h1></body></html>';
  });

  final context = SecurityContext(withTrustedRoots: true);
  var chain = Platform.script.resolve('ssl_chain.pem').toFilePath();
  var key = Platform.script.resolve('ssl_key.pem').toFilePath();

  context.useCertificateChain(chain);
  context.usePrivateKey(key);

  await app.listenSecure(
    port: 3000,
    securityContext: context,
  );
}
