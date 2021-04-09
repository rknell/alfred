# Alfred

A performant, express like server framework with a few bonuses that make life even easier.

[![Build Status](https://travis-ci.org/rknell/alfred.svg?branch=master)](https://travis-ci.org/rknell/alfred)

Quickstart:

@code example/example_quickstart.dart

## Motivation and philosophy

TlDr:
- A minimum of dependencies,
- A minimum of code (199 lines at last check), and sticking close to dart core libraries
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

@code example/example.dart

It should do pretty much what you expect. Handling bodies though do need an "await":

@code example/example_body_parsing.dart

Internally dart provides a body parser, so no extra dependencies there.

The big difference you will see is the option to not call `res.send` or `res.json` etc - although you still can.
Each route accepts a Future as response. Currently you can pass back the following and it will be sent appropriately:

- List<dynamic> - JSON
- Map<String, Object?> - JSON
- String - Plain text
- Stream<List<int>> - Binary
- List<int> - Binary
- File - Binary, with mime type inferred by extension
- Directory - Serves static files

If you want to return HTML, just set the content type to HTML like this:

@code example/example_html.dart

### Custom type handlers
If you want to create custom type handlers, just add them to the type handler
array in the app object. This is a bit advanced, and I expect it would be more
for devs wanting to extend Alfred:

@code example/example_custom_type_handler.dart

## File downloads

As mentioned above - if you want to return a file, simply return it from the route callback.
However the browser will probably try to render it in browser, and not download it.

You can just set the right headers, but there is a handy little helper that will do it all for you.

See `res.setDownload` below.

@code example/example_file_downloads.dart

## But what about Mongo or Postgres or <Databse x>?

The other two systems that inspired this project to be kicked off - Aqueduct and Mongo - both had
some sort of database integration built in.

**You do not need this.**

Access the dart drivers for the database system you want directly, they all use them behind the scenes:

- Mongo - https://pub.dev/packages/mongo_dart
- Postgres - https://pub.dev/packages/postgres
- SQLLite -  https://pub.dev/packages/sqlite3

You will be fine. I have used them this way and they work just fine.

## Low level access

While there are bunch of helpers built in - you have direct access to the low level apis available
from the dart:io package. All helpers are just extension methods to:

- HttpRequest: https://api.dart.dev/stable/2.10.5/dart-io/HttpRequest-class.html
- HttpResponse: https://api.dart.dev/stable/2.10.5/dart-io/HttpResponse-class.html

So you can compose and write any content you can imagine there. The only tangible benefit this library
provides over the core library is the routing and route param extraction.

## Routing

Routing follows a similar pattern to the more basic ExpressJS routes. While there is some regex
matching, mostly just stick with the route name and param syntax from Express:

"/path/to/:id/property" etc

So for example:

@code example/example_routing.dart

You can also use a wildcard for a route, and provided another route hasn't already resolved the
response it will be hit. So for example if you want to authenticate a whole section of an api you
can do this:

@code example/example_middleware_authentication_wildcard.dart

## Middleware

At present the middleware system probably isn't built out enough, but will do for most use cases.

Right now you can specify a middleware for all routes by declaring:

@code example/example_middleware_2.dart

Middleware declared this way will be executed in the order its added to the app.

You can also add middleware to a route like so:

@code example/example_middleware.dart

### What? No 'next'? how do I even?

OK, so the rules are simple. If a middleware resolves a http request, no future middleware gets executed.

So if you return an object from the middleware, you are preventing future middleware from executing.

If you return null it will yield to the next middleware or route.

** returning null is the equivalent of 'next' **

## Error handling

You can either set the status code on the response object yourself and send the data manually, or
you can do this from any route:

app.get("/",(req, res) => throw AlfredException(400, {"message": "invalid request"}));

If any of the routes bubble an unhandled error, it will catch it and throw a 500 error.

If you want to handle the logic when a 500 error is thrown, you can add a custom handler when you
instantiate the app. For example:

@code example/example_error_handling.dart

### 404 Handling

404 Handling works the same as 500 error handling (or uncaught error handling). There is a default
behaviour, but if you want to override it, simply handle it in the app declaration.

@code example/example_missing_handler.dart
## Static Files

This one is super easy - just pass in a public path and a dart Directory object and Alfred does
the rest.

@code example/example_static_files.dart

## CORS

There is a cors middleware supplied for your convenience.

@code example/example_cors.dart

## Logging

For more details on logging [click here](documentation/logging.md).
