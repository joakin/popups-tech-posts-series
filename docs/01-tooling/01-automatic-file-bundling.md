## Automatic JavaScript file bundling and library consumption

### Intro

With MediaWiki [ResourceLoader][] JavaScript files are run without a module
system, so files have to export properties to and consume properties from the
global scope, defined by other files.

This has caused issues in the development workflows related to the project's
JavaScript sources, and the use of JavaScript libraries from the OSS ecosystem.
Organizing the code, trying to keep it maintainable, and understanding how it is
structured has a big cost on the project's quality, development and maintenance.

#### Application JavaScript sources

The order in which these files needs to be loaded so that all dependencies are
set properly then needs to be [manually specified in
`extension.json`][scripts-order] by file name.  As such, there are two sources
of truth:

* The configuration that specifies some order of files,
* And the source code that implicitly uses files in some order.

The order in which parts your program is interpreted is defined outside of the
program itself. At the file level, your file must be written with foreknowledge
about which files have been loaded, which is defined elsewhere.

If you are doing anything mildly complex, you will end up with a big list of
JavaScript files that depend on each other. Having to manually understand that
dependency graph based on the list of dependencies on a JSON file and how the
files use, define, or re-define global variables from or for other files, and
managing a module's internal state, can be quite of a headache.

Changes to the source code, moving lines in the same file, refactoring code to
other and new files, adding new code that uses other files, removing code, ...

All of these become really hard really quickly. In the end, **organizing your
code, trying to keep it maintainable, and understanding how it is structured
have a very big cost on the project's quality, development and maintenance**.

Figuring out if the files are specified in order properly in the configuration
after and while you make changes has a high potential for obscure runtime bugs
by forgetting or not seeing implicit dependencies in the manual order of files.

#### Libraries

In order to consume libraries for the front-end code, right now we rely on
manually (or by script) pulling down npm dependencies or files from a website
and including them in the repository. This is hard to verify, keep up to date,
and cumbersome. If necessary, it should be possible to specify dependencies with
the versions and have them be automatically included in the assets we serve from
a trustworthy source. It should be easy to check if the libraries are outdated,
and update them.

### Requirements

For developing JavaScript files for the front-end:

* There must be a single source of truth for the dependency resolution
* Files should be authored in a standard module system instead of relying in the
  global namespace
* Moving code and files should be low cost and not trigger runtime errors in
  production if the dependencies are not properly specified
* If possible, it should be easier to tap into npm libraries for our front-end
  needs, and check for updates (see [related discussion][T107561])

### Solutions

We considered our options, and after discussion among the engineers, we decided
that:

* We would use a node.js based file bundler ([webpack][]), in order to:
  * automatically bundle our JS sources with a single source of truth for
    intra-module dependencies and asset load order (the source code itself via
    import/export statements)
  * use a standard module system (we started with common.js and afterwards
    migrated to ES modules when finalized)
  * validate the dependency graph and asset building before going to production
    (webpack statically analyzes the asset tree and fails on build)
* We would introduce a build step to compile sources into production worthy
  assets
* We would use ResourceLoader as the way to **serve** the JS bundle(s) and to
  specify other dependencies (images, i18n messages, styles)

You can read some more details in the architecture design record [4. Use
webpack][use-webpack] that we wrote when we discussed this in the team.

#### Why webpack and not `<my-favorite-tool>`?

We looked at the ecosystem of bundlers at the time, and this is a summary of
our evaluation:

* Browserify: Great tool, shrinking community and support in favor of others
* Rollup: Great tool, specialized in bundling code for producing libraries, not
  applications
* Webpack: Great tool, community, maintainers, financial support, mindshare and
  ecosystem of tools

We are not married to, or using any webpack specific features, so we can migrate
from this tool in the future if it becomes a problem.

### Results

* We introduced `webpack` ([config][webpack-config]) and [build scripts][]
* The JS files are located in [src/][src] and use EcmaScript modules
  ([example][es-modules-example])
* The production assets get built into [/resources/dist][dist] to be served by
  ResourceLoader
* We added a CI step in the `npm-test` job that checks built assets have been
  commited and up to date ([check-built-assets][check-built-assets])
* Added a precommit hook that automatically runs the build step and adds the
  built assets ([precommit][precommit])

These are some of the benefits we have seen after the introduction of these
changes:

* ResourceModules configuration reduced for JS files, file order is automatic
  now, source code is the single truth for dependency order
  * [Before][scripts-order], and [after][scripts-after] (no manual ordering of
    files)
* Decreased cost and burden for splitting modules, reusing code, adding new code
  since file order is automatically sorted out
* Source maps in development that point to the original modules in `src/` thanks
  to webpack
* Anecdotally, faster ResourceLoader performance by offloading file parsing and
  bundling to the node.js CLI tool watcher (`npm start`)
* We bundle `redux` and `redux-thunk` from npm, based on the [pinned
  versions][redux-deps] from `package.json`
  * `npm outdated` will show if there are new versions of the libraries
  * `npm update redux` will update the library, and be bundled in our sources
    when we `npm run build`
  * The libraries passed [security review][redux-security], the hash is in
    `package-lock.json` and the build is verified independently in CI by
    a jenkins job from the npm version
* By using standard module systems, it enables us to use our sources in node.js,
  which unlocks the possibility to run unit tests for the frontend code in
  node.js for faster test runs and feedback loop for developers

### Problems

The approach is a bit controversial since MediaWiki extensions usually don't
have build steps, so there was no easy setup for CI and the deployment pipeline
to run a build step before running jobs or deploying.

As such, we ended up committing the built sources to the repository, which is
fine with the CI step and the pre-commit hook mentioned before, but has an
annoying inconvenience: every time a patch is merged with the corresponding
generated asset (`resources/dist/*`), any pending patches on Gerrit that also
need to regenerate the asset (because they touch sources in `src/`), will now be
on merge conflict with master.

We have discussed in phabricator and in wikitech-l:

* [[Wikitech-l] How does a build process look like for a mediawiki extension
  repository?][build-process-mail]
* [T158980: Generate compiled assets from continuous integration][T158980]
 
But sadly didn't get to any concrete steps. If you think you can help with this
issue we would really appreciate your help, as we would like to help other
projects, people and teams be able to use build steps in their extensions.

Right now, we sidestep the issues with a bot we have configured for the
repository, that responds to the command `rebase` (parallel to the `recheck`
command that jenkins-bot responds to. On comment, the bot will download the
patch, rebase it with master, run the build step, and submit a new patch without
the conflict.

As an interim solution it works and allows us to move along, but if we want to
adopt this process for other projects we would really like to have a more
streamlined solution.

### Conclusion

This change has worked very well for us, decreasing the cognitive load and
allowing us to work more effectively on our JS files. We recommend it if you
have many JS files or ResourceLoader modules, and the order and dependencies are
causing you headaches.

We hope to work together in standardizing some sort of CI + deploy process
so that projects on the MediaWiki ecosystem can leverage build steps to improve
their workflows and leverage powerful tools.


[ResourceLoader]: https://www.mediawiki.org/wiki/ResourceLoader
[T107561]: https://phabricator.wikimedia.org/T107561
[T158980]: https://phabricator.wikimedia.org/T158980
[build scripts]: https://github.com/wikimedia/mediawiki-extensions-Popups/blob/2ddf8a96d8df27d6b5e8b4dd8ef33581951db9fe/package.json#L4-L5
[build-process-mail]: https://lists.wikimedia.org/pipermail/wikitech-l/2017-June/088264.html
[check-built-assets]: https://github.com/wikimedia/mediawiki-extensions-Popups/blob/2ddf8a96d8df27d6b5e8b4dd8ef33581951db9fe/package.json#L11
[dist]: https://github.com/wikimedia/mediawiki-extensions-Popups/tree/2ddf8a96d8df27d6b5e8b4dd8ef33581951db9fe/resources/dist
[es-modules-example]: https://github.com/wikimedia/mediawiki-extensions-Popups/blob/2ddf8a96d8df27d6b5e8b4dd8ef33581951db9fe/src/actions.js#L5-L7
[precommit]: https://github.com/wikimedia/mediawiki-extensions-Popups/blob/2ddf8a96d8df27d6b5e8b4dd8ef33581951db9fe/package.json#L13
[redux-deps]: https://github.com/wikimedia/mediawiki-extensions-Popups/blob/2ddf8a96d8df27d6b5e8b4dd8ef33581951db9fe/package.json#L31-L32
[redux-security]: https://phabricator.wikimedia.org/T151902
[scripts-after]: https://github.com/wikimedia/mediawiki-extensions-Popups/blob/2ddf8a96d8df27d6b5e8b4dd8ef33581951db9fe/extension.json#L89-L90
[scripts-order]: https://github.com/wikimedia/mediawiki-extensions-Popups/blob/398ffb0e435f61133f6478f306ef266e147c9dea/extension.json#L75-L112
[src]: https://github.com/wikimedia/mediawiki-extensions-Popups/tree/2ddf8a96d8df27d6b5e8b4dd8ef33581951db9fe/src
[use-webpack]: https://github.com/wikimedia/mediawiki-extensions-Popups/blob/master/doc/adr/0004-use-webpack.md
[webpack-config]: https://github.com/wikimedia/mediawiki-extensions-Popups/blob/2ddf8a96d8df27d6b5e8b4dd8ef33581951db9fe/webpack.config.js
[webpack]: https://webpack.js.org/
