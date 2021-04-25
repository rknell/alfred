# Background, philosophy & motivation

I came to dart with a NodeJS & Mongo / React Native & Cordova background. I had used express for
my server framework, almost always calling "res.json()". I just wanted a simple framework that would
allow me to pump out apps using dart on the server.

## Aqueduct
I started with Aqueduct - It seemed like it was the most popular and better supported of the ones I
looked at. Aqueduct caused a bunch of errors that were nearly impossible to debug after you scratched
the surface. I was nervous about the server framework having so much of an opinion about the database
as well as the web server - I just wanted something that did one thing well.

## Angel
Then I moved to Angel. Angel seemed a little less popular but concerned me because it was trying to
do "everything" with one developer. It proved to be an excellent framework and its creator Tobe is
a real asset to the dart community. Unfortunately he decided to discontinue dev, and it was just too
big of a project to crack. I wanted something smaller.

Then Null safety hit and I realised that betting big on these huge libraries was a bit of a risk.
I now have a number of projects I need to migrate off the platform, for something that should be pretty
simple.

Hence Alfred was born. It's a couple of hundred lines of code and was largely pumped out over a weekend. 
It should be trivial for the community to maintain if it comes to that - but also easy for myself to 
support and run the project.

## Shelf

A number of people have asked "why are you just reimplementing shelf?"

The core philosophy of shelf is composability - you can grab and mix and match a bunch of components
from the community and create your own server. This means that a user need to 
grab a bunch of different imports and find different parts of the ecosystem
in order to get up and running. While its great for democracy and gives you lots of options - it comes with 
the added burden of needing to work out what configuration will actually work.

It also means that over time you will be continually battling packages that are
no longer maintained and fall by the wayside - and you want to hope that the community
has already picked up the slack somewhere. I want a server package that will just
keep on rolling 5 years from now. This is why there are a minimum of dependencies on Alfred
and everywhere I can I base the code on core dart libraries. They may change and break things
but it will be predictable.

Keeping the codebase small means there is very little that needs to be maintained.

In order to allow the community to create extensions, Alfred is really extensible. Instead of taking
the shelf route of forcing you to plug extra bits in, alfred comes with the keys included and allows
you to sub out any parts if the default doesn't do exactly what you want. So for example you can provide your own logger, but if 
you don't, logging will work with a default one. Type handlers are completely configurable, but comes
with a set of preconfigured ones that should do everything you need. 