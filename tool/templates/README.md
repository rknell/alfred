# Alfred

A performant, expressjs like web server / rest api framework thats easy to use and has all the bits in one place.
[![Build Status](https://github.com/rknell/alfred/workflows/Dart/badge.svg)](https://github.com/rknell/alfred/actions)

Quickstart:

@code example/example_quickstart.dart

There is also a 6 part video series that walks you through creating a web server using Alfred from start to deployment, including databases and authentication. You can find that here: https://www.youtube.com/playlist?list=PLkEq83S97rEWsgFEzwBW2pxB7pRYb9wAB

# Index
- [Core principles](#core-principles)
- [Usage overview](#usage-overview)
    - [Quick start guide](#quick-start-guide)
- [Routing & incoming requests](#routing--incoming-requests)
    - [Route params](#route-params)
    - [Query string variables](#query-string-variables)
    - [Body parsing](#body-parsing)
    - [File uploads](#file-uploads)
- [Middleware](#middleware)
    - [No 'next'?](#what-no-next-how-do-i-even)
    - [CORS](#cors)
- [Responses](#responses)
    - [Custom type handlers](#custom-type-handlers)
    - [Static Files](#static-files)
    - [File downloads](#file-downloads)
- [Error handling](#error-handling)
    - [404 Handling](#404-handling)
- [Databases](#but-what-about-mongo-or-postgres-or-databse-x)
- [What I want to do isn't listed](#what-i-want-to-do-isnt-listed)
- [Websockets](#websockets)
- [Logging](#logging)
    - [Print routes](#print-routes)
- [Multi threading & isolates](#multi-threading-and-isolates)
- [Contributions](#contributions)

## Core principles
- A minimum of dependencies,
- A minimum of code and sticking close to dart core libraries - easy to maintain!
- Ease of use
- Predictable, well established semantics
- 90%+ of everything you need all ready to go

[Read about the background behind the project or why its different to shelf](documentation/background.md)

## Usage overview

If you have ever used expressjs before you should be right at home:

@code example/example.dart

It should do pretty much what you expect. Handling bodies though do need an "await":

@code example/example_body_parsing.dart

Internally dart provides a body parser, so no extra dependencies there.

The big difference you will see is the option to not call `res.send` or `res.json` etc - although you still can.
Each route accepts a Future as response. Currently you can pass back the following and it will be sent appropriately:

| Return Dart Type | Returning REST type |
| ----------------- | ------------------ |
| `List<dynamic>` | JSON |
| `Map<String, Object?>` | JSON |
| Serializable object (Object.toJSON or Object.toJson) * see note | JSON |
| `String` | Plain Text |
| `Stream<List<int>>` | Binary |
| `List<int>` | Binary |
| `File` |  Binary, with mime type inferred by extension |
| `Directory` | Serves static files |

\* If your object has a "toJSON" or "toJson" function, alfred will run it, and then return the result

If you want to return HTML, just set the content type to HTML like this:

@code example/example_html.dart

If you want to return a different type and have it handled automatically, you can extend Alfred with
[custom type handlers](#custom-type-handlers).

### Quick start guide

If its all a bit overwhelming @iapicca put together a quick start guide which goes into a little 
more detail: https://medium.com/@iapicca/alfred-an-express-like-server-framework-written-in-dart-1661e8963db9

## Routing & incoming requests

Routing follows a similar pattern to the more basic ExpressJS routes. While there is some regex
matching, mostly just stick with the route name and param syntax from Express:

"/path/to/:id/property" etc

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

@code example/example_routing.dart

You can also use a wildcard for a route, and provided another route hasn't already resolved the
response it will be hit. So for example if you want to authenticate a whole section of an api youc 
can do this:

@code example/example_middleware_authentication_wildcard.dart

### Route params

You can access any params for routes from the `req.params` object as below:

@code example/example_routing.dart

### Query string variables

Querystring variables are exposed `req.uri.queryParameters` object in the request as below:

@code example/example_querystring.dart

### Body parsing

To access the body, simply call `await req.body`.

Alfred will interpret the body type from the content type headers and parse it appropriately. It handles url encoded, multipart & json bodies out of the box.

@code example/example_body_parsing.dart

### File uploads

To upload a file the body parser will handle exposing the data you need. Its actually pretty easy
just give it a go and set a breakpoint to see what the body parser spits back.

A working example of file uploads is below to get you started:

@code example/example_upload_file.dart

## Middleware

You can specify a middleware for all routes by using wildcards:

@code example/example_middleware_2.dart

Middleware declared this way will be executed in the order its added to the app.

You can also add middleware to a route, this is great to enforce authentication etc on an endpoint:

@code example/example_middleware.dart

### What? No 'next'? how do I even?  
OK, so the rules are simple. If a middleware resolves a http request, no future middleware gets executed.

So if you return an object from the middleware, you are preventing future middleware from executing.

If you return null it will yield to the next middleware or route.

** returning null is the equivalent of 'next' **

### CORS

There is a cors middleware supplied for your convenience. Its also a great example of how to write a middleware for Alfred

@code example/example_cors.dart

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

@code example/example_custom_type_handler.dart

### Static Files, uploads and deleting

This one is super easy - just pass in a public path and a dart Directory object and Alfred does
the rest.

@code example/example_static_get.dart

You can also pass in a directory and a POST or PUT command and upload files to a local directory if 
you are using multipart/form encoding. Simply supply the field as `file`:

@code example/example_static_upload.dart

If you want to delete a file?

@code example/example_static_delete.dart

Security? Build in a middleware function to authenticate a user etc. 

### File downloads

As mentioned above - if you want to return a file, simply return it from the route callback.
However the browser will probably try to render it in browser, and not download it.

You can just set the right headers, but there is a handy little helper that will do it all for you.

The file handler fully supports resumable downloads (RFC9110 compliant), including:
- Range requests for partial content
- Multiple range requests with multipart responses
- Conditional requests using ETags and Last-Modified dates
- Proper handling of If-Range header
- Support for suffix ranges (e.g., last 500 bytes)

See `res.setDownload` below.

@code example/example_file_downloads.dart

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

@code example/example_websocket/example_websocket.dart

## Logging

For more details on logging [click here](documentation/logging.md).

### Print routes

Want to quickly print out the registered routes? (recommended when you fire up the server) 
call Alfred.printRoutes ie:

@code example/example_print_routes.dart

## Multi threading and isolates

You can use the app in multithreaded mode. When spawning this way, requests are evenly distributed
amongst the various isolates. Alfred is not particularly prescriptive about how you manage the isolates
just that "it works" when you fire up multiples.

@code example/example_multithreading.dart

# Deployment

There are many ways to skin this cat, you can upload the source code to a VPS yourself, build a binary locally and upload it to a server somewhere, but a fairly elegant way to accomplish a production level deployment is to containerize an AOT build of the server and run it on a PAAS.

Lucky there is a tutorial for that!
https://ryan-knell.medium.com/build-and-deploy-a-dart-server-using-alfred-docker-and-google-cloud-run-from-start-to-finish-d5066e3ab3c6

# Contributions

PRs are welcome and encouraged! This is a community project and as long as the PR keeps within the key principles listed it will probably be accepted. If you have an improvement you would like to to add but are not sure just reach out in the issues section.

NB. The readme is generated from the file in tool/templates/README.md which pulls in the actual source code from the example dart files - this way we can be sure its no pseudocode! If you need to change anything in the documentation please edit it there.

Before you submit your code, you can run the `ci_checks.sh` shell script that will do many of the tests the CI suite will perform.