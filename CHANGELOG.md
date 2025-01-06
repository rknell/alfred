# Changelog

## 1.1.2+1
- Accidentally bundled some breaking code i was working on, reverted.

## 1.1.2
- Added support for resumable downloads (RFC9110 compliant)
  - Implemented range requests with single and multiple ranges
  - Added support for conditional requests with ETags and Last-Modified dates
  - Added proper handling of If-Range header
  - Added support for suffix ranges and multipart/byteranges responses

## 1.1.1

- Adding additional crash protection

## 1.1.0+2

- Testing and updating compatibility with dart 3.0.0

## 1.1.0+1

- Readme edit

## 1.1.0+0

- Small breaking change - when body parsing fails Alfred now throws a BodyParserException which can be caught and handled manually. This may affect you if you have a try catch block but expect it to not catch (which lets face it is unlikely!)

## 1.0.0+1

- Just a bump to update the readme

## 1.0.0

- Moving to dart v2.17.x (thanks @NathanDraco22)
- Fixing bug which prevent correct route parsing (thanks @jodinathan)
- Adding modular routes with path prefixes and RouteGroups (thanks @scroff)
- Removing outdated dependencies and moving to new linter (thansk @aadarshadhakalg)
- Fixed a bug on dart 2.18 where regex typed routes wouldn't parse correctly.

## 0.1.7

- Updating the CORS headers to also allow Access-Control-Expose-Headers thanks @Donk3ys


## 0.1.6+1

- Fixing a directory traversal vulnerability. Highly recommended upgrade to this version. Thanks @d-markey & @seceba for this one.

## 0.1.6

- Adding native support for SSL (thanks @BrunoMoraes-Z and @d-markey for QA)
- Fixing crash when throwing an AlfredException after already setting a header

## 0.1.5+3

- Fixing route handling if you have a parameter on the route. ie /:id

## 0.1.5+2

- Fixing bug that would try and listen to the stream from the body parser twice. Alfred now caches the body in the request store;

## 0.1.5+1

- Updating description to be easier to be found by pub.dev search

## 0.1.5

- Been a while since the last published update... lots of little changes but very few bugs. However thanks to @d-markey the routing logic has been completely rewritten though non api breaking, allowing far more complex matching of route parameters.
- Fixed a bug that would overwrite the file content type if you manually specified it
- Thanks to @d-markey for some other efficiency improvements as well

## 0.1.4+5

- Fixing incorrect mime type recognition 

## 0.1.4+4

- Updating readme with deployment info

## 0.1.4+3

- Removing a warning about returning a response with no content - it wasn't very reliable and also not that helpful

## 0.1.4+2

- It helps if you actually build the docs first

## 0.1.4+1

- Adding file upload docs

## 0.1.4

- Adding Alfred.bodyAsJsonMap and Alfred.bodyAsJsonList functions
- Fixing cors plugin to handle options call correctly
- Adding printRoutes function
- Fix issue with serialized objects that wasn't caught in tests

## 0.1.3

- Adding support for json serialized objects

## 0.1.2+1

- Updating readme

## 0.1.2

- Adding support for multithreading / isolates

## 0.1.1

- Improve directory handling
- Better 404 handling
- Changed type handler functions signature
- Uri decodes route params

## 0.1.0

- Adding custom logging
- Releasing API update for general use

## 0.1.0-alpha.7

- Better handling when there is no appropriate type handler

## 0.1.0-alpha.6

- Removed dependency on UUID
- Improved logic for storage plugin

## 0.1.0-alpha.5

- Added web socket support
- Clear support for nested routes
- Preventing a full crash in some circumstances
- Support for Single Page Apps

## 0.1.0-alpha.4

- Added support for "plugins" to extend the http request object and store data
- Added ability to listen to all closed responses (great for logging or cleaning up plugin logic)
- Added req.setStoreValue and req.getStoreValue methods to persist data across middleware - WARNING - this API may change before 0.1.0 lands
- Enabled strong mode (thanks @felixblaschke) Also a big thanks for all the other code analysis you have performed and advice given
- Cleaned up some functions to simplify them (thanks @ykmnkmi)

## 0.1.0-alpha.3

- Bug fix for return types

## 0.1.0-alpha.2

- Some fixes for CORS & readme example

## 0.1.0-alpha.1

- Readme correction for static routes

## 0.1.0-alpha.0

- Huge update, 
- BREAKING: removed static routes, you now return a directory and specify a wildcard in the routes
- BREAKING: renamed RequestMethod to just Method
- You now have wildcards in all parts of the routes
- There is now an optional CORS middleware
- Support for PATCH and OPTIONS methods added
- You can now create custom type handlers or override the default ones
- Bug fix: Middleware now works on all methods
- TODO: document some of the new stuff!

## 0.0.3+2

- Removing unused dependency

## 0.0.3+1

- Fixing repo link in dart pub

## 0.0.3

- Fixing route params

## 0.0.2+1

- Another big README.md update, fixing lots of examples

## 0.0.2

- Fixing bug for routes that are only "/"

## 0.0.1+1

- Readme corrections

## 0.0.1

- Initial version
