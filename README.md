# Alfred

A performant, express like server framework with a few bonuses that make life even easier.

[![Build Status](https://travis-ci.org/rknell/alfred.svg?branch=master)](https://travis-ci.org/rknell/alfred)

Quickstart:
```dart
main(){
  final app = Alfred();
  
  app.get("/example", (req, res) => "Hello world");

  app.listen();

  print("Listening on port 3000");
}
``` 

## Motivation and philosophy

TlDr:  
    - A minimum of dependencies, 
    - A minimum of code (145 lines at last check), and sticking close to dart core libraries
    - Ease of use
    - Predictable, well established semantics

I came to dart with a NodeJS / React Native & Cordova background. Previously I had used express for
my server framework, almost always calling "res.json()". I just wanted a simple framework that would
allow me to pump out apps using dart on the server.

I started with Aqueduct - It seemed like it was the most popular and better supported of the ones I 
looked at. Aqueduct caused a bunch of errors that were nearly impossible to debug after you scratched 
the surface.

Then I moved to Angel. Angel seemed a little less popular but concerned me because it was trying to
do "everything" with one developer. It proved to be an excellent framework and its creator Tobe is
a real asset to the dart community. Unfortunately he decided to discontinue dev, and it was just too
big of a project to crack. I wanted something smaller.

Then Null safety hit and I realised that betting big on these huge libraries was a bit of a risk.
I now have a number of projects I need to migrate off the platform, for something that should be pretty
simple.

Hence Alfred was born. Its (at the day of this writing) a couple of hundred lines of code. It should
be trivial for the community to maintain if it comes to that - but also easy for myself to maintain
and run the project.

## Usage

if you have ever used expressjs before you should be right at home

```dart
main() async {
  final app = Alfred();

  app.get("/text", (req, res)=> "Text response");

  app.get("/json", (req, res)=> {"json_response": true});

  app.get("/jsonExpressStyle", (req, res) {
    res.json({"type": "traditional_json_response"});
  });

  app.get("/file", (req, res)=>File("test/files/image.jpg"));

  app.get("/html", (req, res){
    res.contentType = ContentType.html;
    return "<html><body><h1>Test HTML</h1></body></html>";
  });

  await app.listen(6565); //Listening on port 6565 
}
```

It should do pretty much what you expect. Handling bodies though do need an "await":

```dart
main() async {
  final app = Alfred();

  app.post("/post-route", (req, res) async {
    final body = jsonDecode(await req.body); //JSON body
  });

  await app.listen(); //Listening on port 3000
 
}
```

Internally dart provides a body parser, so no extra dependencies there.

The big difference you will see is the option to not call `res.send` or `res.json` etc - although you still can.
Each route accepts a Future as response. Currently you can pass back the following and it will be sent appropriately:

List<dynamic> - JSON
Map<String, Object?> - JSON
String - Plain text
Stream<List<int>> - Binary
List<int> - Binary
File - Binary, with mime type inferred by extension

If you want to return HTML, just set the content type to HTML like this:

```dart
main() async {
  final app = Alfred();

  app.get("/html", (req, res){
      res.headers.contentType = ContentType.html;
      return "<html><body><h1>Title!</h1></body></html>";
  });

  await app.listen(); //Listening on port 3000
 
}
```

## File downloads

As mentioned above - if you want to return a file, simply return it from the route callback.
However the browser will probably try to render it in browser, and not download it.

You can just set the right headers, but there is a handy little helper that will do it all for you.

See `res.setDownload` below.

```dart
main() async {
  final app = Alfred();

  app.get("/image/download", (req, res) {
    res.setDownload(filename: "image.jpg");
    return File("model10.jpg");
  });

  await app.listen(); //Listening on port 3000
}
```

## But what about Mongo or Postgres or <Databse x>?

The other two systems that inspired this project to be kicked off - Aqueduct and Mongo - both had
some sort of database integration built in.

You do not need this.

Access the dart drivers for the database system you want directly, they all use them behind the scenes:

Mongo - https://pub.dev/packages/mongo_dart
Postgres - https://pub.dev/packages/postgres
SQLLite -  https://pub.dev/packages/sqflite (careful about this one its mac only, just for example)

You will be fine. I have used them this way and they work just fine.

## Low level access

While there are bunch of helpers built in - you have direct access to the low level apis available
from the dart:io package. All helpers are just extension methods to:

HttpRequest: https://api.dart.dev/stable/2.10.5/dart-io/HttpRequest-class.html
HttpResponse: https://api.dart.dev/stable/2.10.5/dart-io/HttpResponse-class.html

So you can compose and write any content you can imagine there. The only tangible benefit this library
provides over the core library is the routing and route param extraction.

## Routing

Routing follows a similar pattern to the more basic ExpressJS routes. While there is some regex 
matching, mostly just stick with the route name and param syntax from Express:

"/path/to/:id/property" etc

So for example:

```dart
main() async {
  final app = Alfred();
  app.all("/example/:id/:name", (req, res) {
    req.params["id"] != null == true;
    req.params["name"] != null == true;
  });
  final server = await app.listen();
}
```

## Middleware

At present the middleware system probably isn't built out enough, but will do for most use cases.

Right now you can specify a middleware for all routes by declaring:

```dart
main() async {
  final app = Alfred();
  app.all("*", (req, res) {
    // Perform action
  });
  final server = await app.listen();
}
```

Middleware declared this way will be executed in the order its added to the app.

You can also add middleware to a route like so:

```dart
main() async {
  final app = Alfred();
  app.all("/example/:id/:name", (req, res) {
    req.params["id"] != null == true;
    req.params["name"] != null == true;
  }, middleware: [
      exampleMiddleware
    ]);
  
  final server = await app.listen();
}

function exampleMiddlware(HttpRequest req, HttpResponse res){
  // Do work
}
```

### What? No 'next'? how do I even?

OK, so the rules are simple. If a middleware resolves a http request, no future middleware gets executed.

So if you return an object from the middleware, you are preventing future middleware from executing.

If you return null it will yield to the next middleware or route.

*** returning null is the equivalent of 'next' ***

## Error handling

You can either set the status code on the response object yourself and send the data manually, or 
you can do this from any route:

```dart
route(req, res)=>
  throw AlfredException(400, {"message": "invalid request"});
```

If any of the routes bubble an unhandled error, it will catch it and throw a 500 error.

If you want to handle the logic when a 500 error is thrown, you can add a custom handler when you 
instantiate the app. For example:

```dart
main() async {
  app = Alfred(on500: errorHandler);
  await app.listen(port);
  app.get("/throwserror", (req, res) => throw Exception("generic exception")); 
}

function errorHandler(req, res){
    res.statusCode = 500;
    return {"message": "error not handled"};
}
```

### 404 Handling

404 Handling works the same as 500 error handling (or uncaught error handling). There is a default
behaviour, but if you want to override it, simply handle it in the app declaration.

```dart
main() async {
  app = Alfred(on404: missingHandler);
  await app.listen(port);
}

function missingHandler(req, res){
    res.statusCode = 404;
    return {"message": "not found"};
}
```
## Static Files

This one is super easy - just pass in a public path and a dart Directory object and Alfred does
the rest.

```dart
main() async {
  app = Alfred();

  app.static("/public", Directory("test/files"));

  await app.listen(port);
}
```