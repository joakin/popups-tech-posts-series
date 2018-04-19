# Extension:Popups (Page Previews) front-end tooling

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

== Conclusions ==

These changes and workflows have empowered the team to evolve and work
effectively on the project, and we think they could benefit other projects that
are heavy on client side UIs. Despite a few rough corners, and conversations to
be had to streamline this kind of tooling into our ecosystem, we believe it is a
win.

We are very happy to discuss, evolve the current setup, and help other teams or
projects adopt the same kind of tooling. We would love creating opportunities
for shared unified tools around these workflows for the ecosystem.

Please reach out in the comments, in phab tasks, or by email to
`reading-web-team@wikimedia.org`.

[popups]: https://www.mediawiki.org/wiki/Extension:Popups
[mediawiki]: https://www.mediawiki.org/wiki/MediaWiki
