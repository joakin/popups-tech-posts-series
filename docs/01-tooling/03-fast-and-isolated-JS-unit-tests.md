## Fast and isolated JS unit tests

### Intro

For testing frontend code, MediaWiki provides a browser based QUnit setup. For
running the tests, you have to spin up MediaWiki, usually through vagrant, and
load Special:JavaScriptTest in your browser, which will run all the QUnit tests
for all the extensions and MediaWiki itself. From then on, you can filter by
module or string, hide passed tests, and a few other things like select to load
the assets in production mode or development mode (`debug=true`).

Like any testing strategy, this setup comes with tradeoffs. Specifically, there
are a couple of big problems that we have had when working on the frontend code,
which we set out to address when working in `Extension:Popups`:

1.  Tests take a long time to run
2.  It is very hard to write isolated unit tests

#### Tests usually take a long time to run

With this setup, tests have to go through to the MediaWiki server,
ResourceLoader, and then run in the browser. This is especially noticeable in
development mode, which we often enable to get readable stack traces and error
messages on test failures, but makes the test run take a lot longer.

There are also big startup costs, for powering up vagrant and the whole system.

As a result of this, writing tests is costlier than it should be, which
discourages developers to write and run tests, and over time ends up affecting
the quality of our code and QUnit test suites. It also puts significant barriers
to TDD style workflows, which rely on constantly running tests and require a
fast feedback cycle with the developer.

`TODO: Add image or video`

#### It is very hard to write isolated unit tests

In this environment, the real MediaWiki, global state, and the browser
environment are available. As a result, tests are written often as integration
tests, relying on implicit behavior, modules and state being available to
perform the testing.

This is not a problem by itself, integration tests are important and have very
valid use cases and a place in the testing process, but this environment itself
makes it extremely complicated to write isolated unit tests, because of all the
global state, variables, and existing loaded code.

As a result, tests written end up coupled to implicit behavior and state, which
makes them very brittle or overly verbose because of the extensive mocking, and
most of them are big integration tests, which makes them slower to run. All of
this adds up to the previous point, making it an even slower moving setup for
writing tests, with the same outcomes.

`TODO: Find and add an example snippet with the boilerplate required for test set up and tear down.`

### Requirements

Given that:

* Untested code is unmaintained
* Tests that run slow are never run
* Monolithic integration tests are slow to write, read, modify, debug, and
  execute; isolated unit tests are the opposite
* Code that is difficult to test in isolation may be indicative of functional
  concerns
* Efficient tests greatly contribute to efficient development

We need a way to write tests for our frontend JavaScript that:

* Encourage and enforce isolation
  * Without global state or a full MediaWiki environment running
* Start up and run the tests very fast
* Re-run tests when our source files change automatically, without having to
  wait for the developer to go to the browser and run the tests
* Indicate clearly when a failure occurs and where it is

Additional considerations:

* We should rely on familiar tools, at least initially to ease transition and
  migration of existing tests to the new setup

### Solution

We discussed options, and the solution we ended up on was:

* Running the test files in Node.js
  * For speed, ease of setup and running it in CI, and the isolated environment
* With [QUnit][], [jQuery][], [Sinon][] and [jsdom][]
  * To ease migration of existing unit tests to this setup
  * Because of familiarity with the tools (like _Special:JavascriptTest_)

You can read some more details in the architecture design record [7. Prefer
running QUnit tests in Node.js][adr-7].

### Results

We implemented a new npm script `test:node` that is run in CI as part of the
script `test` on the npm job of the extension.

Tests were slowly migrated to `tests/node-qunit` from `tests/qunit` if it was
possible to make them _isolated_. _Integration_ tests were kept in `tests/qunit`
as it made sense since they used the MediaWiki environment more heavily.

We created a small wrapper around QUnit -[mw-node-qunit][]- that we've been
using, which essentially gives us a CLI tool that sets up QUnit with jsdom,
jQuery, and Sinon so that it was easier to migrate the QUnit tests in.

It was quite straight forward to migrate, especially since most of the
Extension:Popups tests from the refactor had been written in a TDD fashion, and
were already mostly isolated.

There was a bit of figuring out because eventually some pieces of code use
`mw.*` functions or helpers, so we created a [`stubs.js`][stubs] where we
created a few stub helpers for the tests.

We also kept a couple of tests as integration tests in `tests/qunit`, but
eventually we did some work to refactor the code and made unit tests for the new
code, so we got rid of the integration tests in MediaWiki entirely.

With this setup, tests run quite fast, and it is feasible (and we do) run them
in watch mode while developing, giving you fast feedback and running your code
on save, all from the terminal/editor.

The environment doesn't have any global state, or implicit knowledge of
MediaWiki, which forces us to write properly isolated tests that don't rely on
implicit behavior or state.

Finally, the move to a Node.js-based toolchain means we are easily able to
leverage other great open source tools without much fuss, for example, for code
coverage. We added another script -[`coverage`][coverage]- which just run the
test command, but with the code coverage tool [`istanbul`][istanbul] first, and
just like that we got back coverage reports for the frontend code.

We recommend this approach for others wanting to improve how they test, and
would be happy to help you figure out if this approach would work for you. For
example, you can use this CLI runner, even if your JS sources just use globals
instead of common.js or ES modules.

### Problems

Overall, the move has gone great and we don't many issues to report.

When migrating existing tests, it is sometimes a bit tricky to figure out how to
move them to the isolated environment, since most of the [MediaWiki JS
library][mw] is not available as an npm package, so in some occasions we had to
restructure the code a bit to not implicitly assume as much of MediaWiki being
available, and other times we had to set up some stubs for the tests to run
well. This had the added benefit that the dependency on MediaWiki core libraries
is explicit in the tests, so we should notice when adding new dependencies or
changing them because of the failing tests, keeping the behavior and
dependencies explicit.

Another extra thing that we have been doing has been maintaining
[`mw-node-qunit`][mw-node-qunit], which has taken a bit of additional time.
Making sure our wrapper works well with qunitjs, and updating the dependency
versions to not fall behind and leverage improvements on the libraries.

`TODO: Remove this paragraph ⬇️ once mw-node-qunit is fixed`. We also expect
some more work on the wrapper as to simplify our implementation and be able to
leverage the superior QUnit.js tap output and the rest of the CLI options like
filters. The good thing is that the CLI wrapper should be useful for any
Wikimedia projects as is.

We will also be looking into moving the repository to the Wikimedia organization
in GitHub if other teams or projects adopt this testing strategy.

### Conclusions

This change has worked really well for us. We are able to run our tests really
fast, even without vagrant running. The environment is isolated and really good
for unit testing. The CLI wrapper had the specific helpers to ease migration
from the existing tests, so it was fairly painless to switch.

Because of all of these, the extension has excellent code coverage, developers
have an easier time contributing tests, and doing TDD is feasible. There is less
uncertainty when refactoring and adding features, and the codebase is easy to
work with. A big part of it is because of the unit testing story.

We're looking forward to adopting the same approach in other repositories and
helping others do the same.

[adr-7]: https://github.com/wikimedia/mediawiki-extensions-Popups/blob/2ddf8a96d8df27d6b5e8b4dd8ef33581951db9fe/doc/adr/0007-prefer-running-qunit-tests-in-node-js.md
[qunit]: https://www.npmjs.com/package/qunitjs
[jquery]: https://www.npmjs.com/package/jquery
[sinon]: https://www.npmjs.com/package/sinon
[jsdom]: https://www.npmjs.com/package/jsdom
[mw-node-qunit]: https://github.com/joakin/mw-node-qunit/
[stubs]: https://github.com/wikimedia/mediawiki-extensions-Popups/blob/2ddf8a96d8df27d6b5e8b4dd8ef33581951db9fe/tests/node-qunit/stubs.js
[coverage]: https://github.com/wikimedia/mediawiki-extensions-Popups/blob/2ddf8a96d8df27d6b5e8b4dd8ef33581951db9fe/package.json#L12
[istanbul]: https://istanbul.js.org/
[mw]: https://doc.wikimedia.org/mediawiki-core/master/js/
[1221]: https://github.com/qunitjs/qunit/issues/1221
[1271]: https://github.com/qunitjs/qunit/pull/1271
