## Intro

This is my attempt at implementing a single page application framework written in Ruby and modeled after AngularJS.

"But wait," you say, "Ruby? That doesn't run in the browser!" It does, in a way, using Opal to transpile Ruby to JS similar to how CoffeeScript is converted to Javascript. I wrote this following the fabulous eBook titled "Build your own Angular." I don't have it to the point where you could write a functioning web app yet, but the foundation is almost there.

Currecently implemented:

- Scopes
- Very simple directives
- A DOM compliler
- Expression parser (inline Ruby, basically)
- Dependency injection.

Included in this repository is a skeleton Rails application the serves as an asset/build pipeline for Opal as well as a way to run specs and create simple server side API to test network (jQuery wrapped in Ruby) code. At some point I would decouple Opular from the Rails app, but it's more conveneient to keep them together for now during heavy development. And also to help anyone who might want to contribute get started.

All Opular (this project!) specific code can be found in app/assets/javascripts/. Note that all the files are named .js.rb, not .js. The asset pipeline will automatically compile these files to pure JS for release to run in a browser.

## Why "Opular?"

Opal-Angular. I'm not very creative.

### DISCLAIMER:

This a purely experimental project and will likely never have any practical value unless you feel you absolutely MUST write your client side web apps in Ruby. It will never perform as well as AngularJS does.

### Related Projects

- http://opalrb.org/
- https://angularjs.org/
- http://teropa.info/build-your-own-angular