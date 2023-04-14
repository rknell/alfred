# Alfred

一个高性能、易于使用、类Expressjs风格的一站式Web服务器/Rest Api框架
[![Build Status](https://github.com/rknell/alfred/workflows/Dart/badge.svg)](https://github.com/rknell/alfred/actions)

快速上手:

```dart
import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  app.get('/example', (req, res) => 'Hello world');

  await app.listen();
}
```

我们提供了一个六集的系列视频帮助您使用Alfred创建一个Web服务器，包含了数据库和身份验证。您可以在Youtube平台观看：https://www.youtube.com/playlist?list=PLkEq83S97rEWsgFEzwBW2pxB7pRYb9wAB

# Index
- [核心原则](#核心原则)
- [使用概述](#使用概述)
    - [快速入门指南](#快速入门指南)
- [路由&传入请求](#路由&传入请求)
    - [路由参数](#路由参数)
    - [查询字符串变量](#查询字符串变量)
    - [解析Body](#解析Body)
    - [上传文件](#上传文件)
- [中间件](#middleware)
    - [没有 "下一步 "吗](#what-no-next-how-do-i-even)
    - [CORS](#cors)
- [响应](#responses)
    - [自定义类型处理程序](#custom-type-handlers)
    - [静态文件](#static-files)
    - [文件下载](#file-downloads)
- [错误处理](#error-handling)
    - [404处理](#404-handling)
- [数据库](#but-what-about-mongo or-postgres or-databse-x)
- [我想做的事没有列出](#what-i-want-to-do-isnt-list)
- [Websockets](#websockets)
- [日志记录](#logging)
    - [打印路线](#print-routes)
- [多线程和isolates](#多线程和isolates)
- [贡献](#contributions)

## 核心原则
- 最小依赖
- 易于使用
- 易于理解、结构良好的源码
- 尽可能少的代码，并紧贴dart的核心库
- 开箱即用(90%以上你所需要的东西都是现成的)

[了解项目背景，以及为什么它和shelf框架不同](documentation/background.md)

## 使用概述

如果你以前使用过Expressjs框架，那么你应该很熟悉：

```dart
import 'dart:io';

import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  app.get('/text', (req, res) => 'Text response');

  app.get('/json', (req, res) => {'json_response': true});

  app.get('/jsonExpressStyle', (req, res) {
    res.json({'type': 'traditional_json_response'});
  });

  app.get('/file', (req, res) => File('test/files/image.jpg'));

  app.get('/html', (req, res) {
    res.headers.contentType = ContentType.html;
    return '<html><body><h1>Test HTML</h1></body></html>';
  });

  await app.listen(6565); // 监听6565端口
}
```

应该和你想得差不多吧，但处理body还需要一个 "await"：

```dart
import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  app.post('/post-route', (req, res) async {
    final body = await req.body; // JSON body
    body != null; // true
  });

  await app.listen(); // 监听3000端口
}
```

dart内置了一个body解析器，所以这里没有额外的依赖。  

你将看到的最大区别是可选的不调用`res.send`或`res.json`等————尽管你也可以这样做。  
每个路由接受一个Future作为响应。目前你可以传回以下内容，并且它将被适当地发送：  

| 返回Dart类型 | 返回REST类型 |
| ----------------- | ------------------ |
| `List<dynamic>` | JSON |
| `Map<String, Object?>` | JSON |
| 可序列化的对象(Object.toJSON或Object.toJson) * 见注释 | JSON |
| `String` | 纯文本 |
| `Stream<List<int>>` | 二进制 |
| `List<int>` | 二进制 |
| `File` |  二进制，由扩展名推断出的MIME类型 |
| `Directory` | 静态文件 |

\* 如果你的对象有一个 "toJSON "或 "toJson "函数，alfred会运行它，然后返回结果。

如果你想返回HTML，只需像这样将content type设置为HTML：

```dart
import 'dart:io';

import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  app.get('/html', (req, res) {
    res.headers.contentType = ContentType.html;
    return '<html><body><h1>Title!</h1></body></html>';
  });

  await app.listen(); // 监听3000端口
}
```

如果你想返回一个不同的类型并让它自动处理，你可以用以下方式扩展Alfred：
[custom type handlers](#custom-type-handlers).

### 快速入门指南

如果看完以上内容后一脸懵逼，可以阅读@iapicca编写的快速入门指南，其中包括了更多细节: https://medium.com/@iapicca/alfred-an-express-like-server-framework-written-in-dart-1661e8963db9

## 路由&传入请求

路由遵循与基本的ExpressJS路由类似的模式。虽然有一些正则匹配，但大多数情况下只是坚持使用Express中的路由名称和参数语法：

比如"/path/to/:id/property"这样的

The Express syntax has been extended to support parameter patterns and types. To enforce parameter
validation, a regular expression or a type specifier should be provided after the parameter name, using
another `:` as a separator:

* `/path/to/:id:\d+/property` will ensure "id" is a string consisting of decimal digits
* `/path/to/:id:[0-9a-f]+/property` will ensure "id" is a string consisting of hexadecimal digits
* `/path/to/:word:[a-z]+/property` will ensure "word" is a string consisting of letters only
* `/path/to/:id:uuid/property` will ensure "id" is a string representing an UUID

Available type specifiers are:

* `int`: a decimal integer
* `uint`: a positive decimal integer
* `double`: a double (decimal form); note that scientific notation is not supported
* `date`: a UTC date in the form of "year/month/day"; note how this type "absorbs" multiple segments of the URI
* `timestamp`: a UTC date expressed in number of milliseconds since Epoch
* `uuid`: a string resembling a UUID (hexadecimal number formatted as `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`); note that no effort is made to ensure this is a valid UUID

| Type Specifier | Regular Expression | Dart type |
| -------------- | ------------------ | --------- |
| `int` | `-?\d+` | `int` |
| `uint` | `\d+` | `int` |
| `double` | `-?\d+(?:\.\d+)` | `double` |
| `date` | `-?\d{1,6}/(?:0[1-9]\|1[012])/(?:0[1-9]\|[12][0-9]\|3[01])` | `DateTime` |
| `timestamp` | `-?\d+` | `DateTime` |
| `uuid` |  `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}` | `String` |

So for example:

```dart
import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();
  app.all('/example/:id/:name', (req, res) {
    req.params['id'] != null;
    req.params['name'] != null;
  });
  app.all('/typed-example/:id:int/:name', (req, res) {
    req.params['id'] != null;
    req.params['id'] is int;
    req.params['name'] != null;
  });
  app.get('/blog/:date:date/:id:int', (req, res) {
    req.params['date'] != null;
    req.params['date'] is DateTime;
    req.params['id'] != null;
    req.params['id'] is int;
  });
  await app.listen();
}
```

You can also use a wildcard for a route, and provided another route hasn't already resolved the
response it will be hit. So for example if you want to authenticate a whole section of an api youc 
can do this:

```dart
import 'dart:async';

import 'package:alfred/alfred.dart';

FutureOr _authenticationMiddleware(HttpRequest req, HttpResponse res) async {
  res.statusCode = 401;
  await res.close();
}

void main() async {
  final app = Alfred();

  app.all('/resource*', (req, res) => _authenticationMiddleware);

  app.get('/resource', (req, res) {}); //Will not be hit
  app.post('/resource', (req, res) {}); //Will not be hit
  app.post('/resource/1', (req, res) {}); //Will not be hit

  await app.listen();
}
```

### 路由参数

You can access any params for routes from the `req.params` object as below:

```dart
import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();
  app.all('/example/:id/:name', (req, res) {
    req.params['id'] != null;
    req.params['name'] != null;
  });
  app.all('/typed-example/:id:int/:name', (req, res) {
    req.params['id'] != null;
    req.params['id'] is int;
    req.params['name'] != null;
  });
  app.get('/blog/:date:date/:id:int', (req, res) {
    req.params['date'] != null;
    req.params['date'] is DateTime;
    req.params['id'] != null;
    req.params['id'] is int;
  });
  await app.listen();
}
```

### 查询字符串变量

Querystring variables are exposed `req.uri.queryParameters` object in the request as below:

```dart
import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  app.post('/route', (req, res) async {
    /// Handle /route?qsvar=true
    final result = req.uri.queryParameters['qsvar'];
    result == 'true'; //true
  });

  await app.listen(); //Listening on port 3000
}
```

### 解析Body

To access the body, simply call `await req.body`.

Alfred will interpret the body type from the content type headers and parse it appropriately. It handles url encoded, multipart & json bodies out of the box.

```dart
import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  app.post('/post-route', (req, res) async {
    final body = await req.body; //JSON body
    body != null; //true
  });

  await app.listen(); //Listening on port 3000
}
```

### 上传文件

To upload a file the body parser will handle exposing the data you need. Its actually pretty easy
just give it a go and set a breakpoint to see what the body parser spits back.

A working example of file uploads is below to get you started:

```dart
import 'dart:io';

import 'package:alfred/alfred.dart';

final _uploadDirectory = Directory('uploadedFiles');

Future<void> main() async {
  final app = Alfred();

  app.get('/files/*', (req, res) => _uploadDirectory);

  /// Example of handling a multipart/form-data file upload
  app.post('/upload', (req, res) async {
    final body = await req.bodyAsJsonMap;

    // Create the upload directory if it doesn't exist
    if (await _uploadDirectory.exists() == false) {
      await _uploadDirectory.create();
    }

    // Get the uploaded file content
    final uploadedFile = (body['file'] as HttpBodyFileUpload);
    var fileBytes = (uploadedFile.content as List<int>);

    // Create the local file name and save the file
    await File('${_uploadDirectory.absolute}/${uploadedFile.filename}')
        .writeAsBytes(fileBytes);

    /// Return the path to the user
    ///
    /// The path is served from the /files route above
    return ({
      'path': 'https://${req.headers.host ?? ''}/files/${uploadedFile.filename}'
    });
  });

  await app.listen();
}
```

## Middleware

You can specify a middleware for all routes by using wildcards:

```dart
import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();
  app.all('*', (req, res) {
    // Perform action
    res.headers.set('x-custom-header', "Alfred isn't bad");

    /// No need to call next as we don't send a response.
    /// Alfred will find the next matching route
  });

  app.get('/otherFunction', (req, res) {
    //Action performed next
    return {'message': 'complete'};
  });

  await app.listen();
}
```

Middleware declared this way will be executed in the order its added to the app.

You can also add middleware to a route, this is great to enforce authentication etc on an endpoint:

```dart
import 'dart:async';

import 'package:alfred/alfred.dart';

FutureOr exampleMiddleware(HttpRequest req, HttpResponse res) {
  // Do work
  if (req.headers.value('Authorization') != 'apikey') {
    throw AlfredException(401, {'message': 'authentication failed'});
  }
}

void main() async {
  final app = Alfred();
  app.all('/example/:id/:name', (req, res) {}, middleware: [exampleMiddleware]);

  await app.listen(); //Listening on port 3000
}
```

### What? No 'next'? how do I even?  
OK, so the rules are simple. If a middleware resolves a http request, no future middleware gets executed.

So if you return an object from the middleware, you are preventing future middleware from executing.

If you return null it will yield to the next middleware or route.

** returning null is the equivalent of 'next' **

### CORS

There is a cors middleware supplied for your convenience. Its also a great example of how to write a middleware for Alfred

```dart
import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  // Warning: defaults to origin "*"
  app.all('*', cors(origin: 'myorigin.com'));

  await app.listen();
}
```

## Responses

Alfred is super easy, generally you just return JSON, a file, a String or a Binary stream and you are all good.

The big difference from express is you will see is the option to not call `res.send` or `res.json` etc - although you still can.
Each route accepts a Future as response. Currently you can pass back the following and it will be sent appropriately:

- `List<dynamic>` - JSON
- `Map<String, Object?>` - JSON
- `String` - Plain text
- `Stream<List<int>>` - Binary
- `List<int>` - Binary
- `File` - Binary, with mime type inferred by extension
- `Directory` - Serves static files

Each type listed above has a `Type Handler` build in. [You can create your own custom type handlers](#custom-type-handlers)

### Custom type handlers
Alfred has a pretty cool mechanism thanks to Dart's type system to automatically resolve a response
based on the returned type from a route. These are called `Type Handlers`.

If you want to create custom type handlers, just add them to the type handler
array in the app object. This is a bit advanced, and I expect it would be more
for devs wanting to extend Alfred:

```dart
import 'package:alfred/alfred.dart';

class Chicken {
  String get response => 'I am a chicken';
}

void main() {
  final app = Alfred();

  app.typeHandlers.add(TypeHandler<Chicken>((req, res, Chicken val) async {
    res.write(val.response);
    await res.close();
  }));

  /// The app will now return the Chicken.response if you return one from a route

  app.get('/kfc', (req, res) => Chicken()); //I am a chicken;

  app.listen(); //Listening on 3000
}
```

### Static Files, uploads and deleting

This one is super easy - just pass in a public path and a dart Directory object and Alfred does
the rest.

```dart
import 'dart:io';

import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  /// Note the wildcard (*) this is very important!!
  app.get('/public/*', (req, res) => Directory('test/files'));

  await app.listen();
}
```

You can also pass in a directory and a POST or PUT command and upload files to a local directory if 
you are using multipart/form encoding. Simply supply the field as `file`:

```dart
import 'dart:io';

import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  app.post('/public', (req, res) => Directory('test/files'));

  await app.listen();
}
```

If you want to delete a file?

```dart
import 'dart:async';
import 'dart:io';

import 'package:alfred/alfred.dart';

FutureOr isAuthenticatedMiddleware(HttpRequest req, HttpResponse res) {
  if (req.headers.value('Authorization') != 'MYAPIKEY') {
    throw AlfredException(
        401, {'error': 'You are not authorized to perform this operation'});
  }
}

void main() async {
  final app = Alfred();

  /// Note the wildcard (*) this is very important!!
  ///
  /// You almost certainly want to protect this endpoint with some middleware
  /// to authenticate a user.
  app.delete('/public/*', (req, res) => Directory('test/files'),
      middleware: [isAuthenticatedMiddleware]);

  await app.listen();
}
```

Security? Build in a middleware function to authenticate a user etc. 

### File downloads

As mentioned above - if you want to return a file, simply return it from the route callback.
However the browser will probably try to render it in browser, and not download it.

You can just set the right headers, but there is a handy little helper that will do it all for you.

See `res.setDownload` below.

```dart
import 'dart:io';

import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  app.get('/image/download', (req, res) {
    res.setDownload(filename: 'image.jpg');
    return File('test/files/image.jpg');
  });

  await app.listen(); //Listening on port 3000
}
```

## Error handling

You can either set the status code on the response object yourself and send the data manually, or
you can do this from any route:

app.get("/",(req, res) => throw AlfredException(400, {"message": "invalid request"}));

If any of the routes bubble an unhandled error, it will catch it and throw a 500 error.

If you want to handle the logic when a 500 error is thrown, you can add a custom handler when you
instantiate the app. For example:

```dart
import 'dart:async';

import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred(onInternalError: errorHandler);
  await app.listen();
  app.get('/throwserror', (req, res) => throw Exception('generic exception'));
}

FutureOr errorHandler(HttpRequest req, HttpResponse res) {
  res.statusCode = 500;
  return {'message': 'error not handled'};
}
```

### 404 Handling

404 Handling works the same as 500 error handling (or uncaught error handling). There is a default
behaviour, but if you want to override it, simply handle it in the app declaration.

```dart
import 'dart:async';

import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred(onNotFound: missingHandler);
  await app.listen();
}

FutureOr missingHandler(HttpRequest req, HttpResponse res) {
  res.statusCode = 404;
  return {'message': 'not found'};
}
```

## But what about Mongo or Postgres or <Database x>?

The other two systems that inspired this project to be kicked off - Aqueduct and Angel - both had
some sort of database integration built in.

**You do not need this.**

Access the dart drivers for the database system you want directly, they all use them behind the scenes:

- Mongo - https://pub.dev/packages/mongo_dart
- Postgres - https://pub.dev/packages/postgres
- SQLLite -  https://pub.dev/packages/sqlite3

You will be fine. I have used them this way and they work.

I have rolled my own classes that act as a sort of ORM, especially around Mongo. Its suprisingly effective
and doesn't rely on much code.

## What I want to do isn't listed

While there are bunch of helpers built in - you have direct access to the low level apis available
from the dart:io package. All helpers are just extension methods to:

- HttpRequest: https://api.dart.dev/stable/2.10.5/dart-io/HttpRequest-class.html
- HttpResponse: https://api.dart.dev/stable/2.10.5/dart-io/HttpResponse-class.html

So you can compose and write any content you can imagine there. If there is something you want to do
that isn't expressly listed by the library, you will be able to do it with a minimum of research into
underlying libraries. A core part of the architecture is to not build you into a wall.

## Websockets

Alfred supports websockets too!

There is a quick chat client in the examples

```dart
import 'dart:async';
import 'dart:io';

import 'package:alfred/alfred.dart';
import 'package:alfred/src/type_handlers/websocket_type_handler.dart';

Future<void> main() async {
  final app = Alfred();

  // Path to this Dart file
  var dir = File(Platform.script.path).parent.path;

  // Deliver web client for chat
  app.get('/', (req, res) => File('$dir/chat-client.html'));

  // Track connected clients
  var users = <WebSocket>[];

  // WebSocket chat relay implementation
  app.get('/ws', (req, res) {
    return WebSocketSession(
      onOpen: (ws) {
        users.add(ws);
        users
            .where((user) => user != ws)
            .forEach((user) => user.send('A new user joined the chat.'));
      },
      onClose: (ws) {
        users.remove(ws);
        for (var user in users) {
          user.send('A user has left.');
        }
      },
      onMessage: (ws, dynamic data) async {
        for (var user in users) {
          user.send(data);
        }
      },
    );
  });

  final server = await app.listen();

  print('Listening on ${server.port}');
}
```

## Logging

For more details on logging [click here](documentation/logging.md).

### Print routes

Want to quickly print out the registered routes? (recommended when you fire up the server) 
call Alfred.printRoutes ie:

```dart
import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  app.get('/html', (req, res) {});

  app.printRoutes(); //Will print the routes to the console

  await app.listen();
}
```

## 多线程和isolates

You can use the app in multithreaded mode. When spawning this way, requests are evenly distributed
amongst the various isolates. Alfred is not particularly prescriptive about how you manage the isolates
just that "it works" when you fire up multiples.

```dart
import 'dart:isolate';

import 'package:alfred/alfred.dart';

Future<void> main() async {
  // Fire up 5 isolates
  for (var i = 0; i < 5; i++) {
    unawaited(Isolate.spawn(startInstance, ''));
  }
  // Start listening on this isolate also
  startInstance(null);
}

/// The start function needs to be top level or static. You probably want to
/// run your entire app in an isolate so you don't run into trouble sharing DB
/// connections etc. However you can engineer this however you like.
///
void startInstance(dynamic message) async {
  final app = Alfred();

  app.all('/example', (req, res) => 'Hello world');

  await app.listen();
}

/// Simple function to prevent linting errors, can be ignored
void unawaited(Future future) {}
```

# Deployment

There are many ways to skin this cat, you can upload the source code to a VPS yourself, build a binary locally and upload it to a server somewhere, but a fairly elegant way to accomplish a production level deployment is to containerize an AOT build of the server and run it on a PAAS.

Lucky there is a tutorial for that!
https://ryan-knell.medium.com/build-and-deploy-a-dart-server-using-alfred-docker-and-google-cloud-run-from-start-to-finish-d5066e3ab3c6

# Contributions

PRs are welcome and encouraged! This is a community project and as long as the PR keeps within the key principles listed it will probably be accepted. If you have an improvement you would like to to add but are not sure just reach out in the issues section.

NB. The readme is generated from the file in tool/templates/README.md which pulls in the actual source code from the example dart files - this way we can be sure its no pseudocode! If you need to change anything in the documentation please edit it there.

Before you submit your code, you can run the `ci_checks.sh` shell script that will do many of the tests the CI suite will perform.