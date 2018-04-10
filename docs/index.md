# Extension:Popups (Page Previews) front-end tech

## Intro

[Extension:Popups][popups] is a [MediaWiki][] extension that shows previews when
hovering a link in a popup.

Extra requirements and a desire to find better ways to code for the frontend
stack led to a series of interesting decisions in terms of tooling and features
that we think could benefit other projects in the MediaWiki ecosystem.

In this series of posts we will explain the different technical decisions and
choices in technology and tooling for the front-end part of the extension. We
will provide reasoning, explanations, pros and cons, and our conclusions.

## Table of contents:

* Tooling
  1.  [Automatic file bundling](./01-tooling/01-automatic-file-bundling.html)
  2.  [Better minification for frontend sources](./01-tooling/02-better-minification-for-frontend-sources.html)
  3.  [Fast and isolated JS unit tests](./01-tooling/03-fast-and-isolated-JS-unit-tests.html)
* Code patterns
  1.  [Factory functions](./02-code-patterns-&-architecture/01-factory-functions.html)

[popups]: https://www.mediawiki.org/wiki/Extension:Popups
[mediawiki]: https://www.mediawiki.org/wiki/MediaWiki
