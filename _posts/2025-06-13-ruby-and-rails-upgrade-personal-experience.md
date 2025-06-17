---
layout: post
title: "Ruby and Rails upgrade: personal experience"
headline: "Ruby and Rails upgrade: personal experience"
modified: 2025-06-13 22:33:44 +0200
description: "A personal reflection on upgrading Ruby and Rails in a project, sharing challenges and lessons learned."
tags: [rails, rails-development, ruby]
featured_post: false
toc: true
image:
---

Good day, everyone! Today, I want to share my personal experience upgrading Ruby and Rails in a project. This is not a tutorial, but rather a reflection on the process, challenges, and lessons learned. I also honestly share where I used AI tools to speed up the process. Where they were useful and where they weren't. The post is quite long, so grab a cup of coffee and enjoy the read.

## Why upgrade Ruby and Rails?

Upgrading Ruby and Rails is necessary to keep your app running smoothly and securely. For me, an additional and undeniable motivation was that Heroku deprecates older Ruby versions. The next Heroku stack will most likely not support Ruby 3.1. Without an upgrade, deployments on Heroku would eventually fail.

The client will definitely stay with Heroku (yes, despite the [recent epic failure](https://www.reddit.com/r/Heroku/comments/1l7sq5p/is_something_happening_cant_access_heroku_also_my/) and price increases). So, I had to upgrade Ruby and Rails to keep the app running on Heroku.

## Current stack of the project

The project ran on Ruby 3.1.4 and Rails 6.1.7.6. Upgrade targets to Ruby 3.4.4 and Rails 7.2.

It’s a Rails monolith mainly serving as a GraphQL API backend. Originally full-stack, the frontend was moved to a separate React app, though some unused legacy controllers, views, helpers, and gems remain.

The codebase isn’t huge — about 100 models, 3 GraphQL schemas, 200 service objects, 60 background jobs, and around 5 actively used controllers.

PostgreSQL is the main DB. Sidekiq is for background jobs. No caching. RSpec/FactoryBot for testing. Rubocop for code linting.

Some places of the app use Dry-Rb gems, including monads and the auto-injector. Since the app was maintained by various developers over the years, it has accumulated different approaches and patterns. Pretty average Rails app, I’d say.

## Iterative changes

I prefer to make small, incremental changes rather than big bang upgrades. This way, I can test each change and ensure everything works as expected. For that reason I started the upgrade with Ruby only, leaving Rails for later. Even though some people might suggest upgrading both Ruby and Rails at the same time, I find it easier to isolate issues when I tackle them one at a time.

## My log of upgrading Ruby

I install Ruby 3.4.4 locally and update the `Gemfile` to use it:

```ruby
ruby '3.4.4'
```

Then I remove the `Gemfile.lock` file and run `bundle install` to generate a new lock file with the updated Ruby version and all dependencies compatible with the new Ruby version. If some gems were not compatible, I would update them to the latest versions that support Ruby 3.4.4.

Fortunately, all gems were installed successfully. But installed gems don't guarantee compatibility. So, right after that, I run the test suite to ensure everything works as expected. Besides tests I have set to myself the following checks to pass:

- Assets precompilation
- Rails console should work
- Rails server should start without errors
- Sidekiq should start without errors
- Rubocop should pass without errors

But first, I need to fix all tests.

Next you see the list of issues/exceptions I encountered during running tests and the fixes I made.

---
💣 `uninitialized constant GraphQL::Compatibility::ExecutionSpecification::SpecificationSchema::OpenStruct`

✅ add `require 'ostruct'` in `config/application.rb`.

New Ruby no longer loads `OpenStruct` (and some more standard libraries) by default.

---
💣 `uninitialized constant ActiveSupport::LoggerThreadSafeLevel::Logger`

✅ add `require 'logger'` in `config/application.rb`.

New Ruby no longer loads `Logger` by default.

---
💣

```
Bundler::GemRequireError:
  There was an error while trying to load the gem 'bootstrap'.
  Gem Load Error is: bootstrap-rubygem requires a Sass engine. Please add dartsass-sprockets, sassc-rails, dartsass-rails or cssbundling-rails to your dependencies.
```
✅ add `sassc-rails` gem to the `Gemfile`.

The project has `bootstrap` gem. Even though it's useless since the frontend is now a separate React app, I decide to keep it for now. Removing the legacy code is a separate task, and I don't want to mix it with the Ruby upgrade.

---
💣

```
Bundler::GemRequireError:
  There was an error while trying to load the gem 'sidekiq-cron'.
  Gem Load Error is: cannot load such file -- sidekiq/util
  Backtrace for gem load error is:
```

✅ upgrade `sidekiq-cron` gem to the latest version.

---
💣

```
TSort::Cyclic:
  topological sort failed: [...a long list of output...]
```

✅ removing `dartsass-sprockets` and `dartsass-rails` from the `Gemfile`.

Neither dart, nor sass engines are used in the project, so I remove them to avoid the cyclic dependency error. The gems were added by the recommendation of the `bootstrap` gem. But those gems are not needed for the project, so I remove them.

---

At this point the tests started to run, not all of them passed, but at least I could see the progress. I leave the tests fixing for later and move on to the next step - assets precompilation. On that step I encountered the following issues.

---
💣 `LoadError: cannot load such file -- drb (LoadError)`

✅ add gem `drb` to the `Gemfile`.

New Ruby no longer loads `drb` by default, but it is required by the `rails` gem for assets precompilation.

---
💣 `error Command "build:css" not found.`

✅ remove `cssbundling-rails` gem from the `Gemfile`.

The `cssbundling-rails` gem is not used in the project, so I remove it to avoid the error. The project uses `sassc-rails` for CSS processing, so I don't need `cssbundling-rails`. This gem was also added by the recommendation of the `bootstrap` gem.

---
💣 Assets precompilation failed on Heroku

```
[webpack-cli] Error: error:0308010C:digital envelope routines::unsupported
           at new Hash (node:internal/crypto/hash:79:19)
           at Object.createHash (node:crypto:139:10)
           at CompressionPlugin.taskGenerator (/tmp/build_8801e356/node_modules/compression-webpack-plugin/dist/index.js:163:38)
           at taskGenerator.next (<anonymous>)
           at /tmp/build_8801e356/node_modules/compression-webpack-plugin/dist/index.js:216:49
           at CompressionPlugin.runTasks (/tmp/build_8801e356/node_modules/compression-webpack-plugin/dist/index.js:236:9)
           at /tmp/build_8801e356/node_modules/compression-webpack-plugin/dist/index.js:270:18
           at _next0 (eval at create (/tmp/build_8801e356/node_modules/tapable/lib/HookCodeFactory.js:33:10), <anonymous>:37:17)
           at eval (eval at create (/tmp/build_8801e356/node_modules/tapable/lib/HookCodeFactory.js:33:10), <anonymous>:53:1)
           at WebpackAssetsManifest.handleEmit (/tmp/build_8801e356/node_modules/webpack-assets-manifest/src/WebpackAssetsManifest.js:486:5)
           at AsyncSeriesHook.eval [as callAsync] (eval at create (/tmp/build_8801e356/node_modules/tapable/lib/HookCodeFactory.js:33:10), <anonymous>:49:1)
           at AsyncSeriesHook.lazyCompileHook (/tmp/build_8801e356/node_modules/tapable/lib/Hook.js:154:20)
           at Compiler.emitAssets (/tmp/build_8801e356/node_modules/webpack/lib/Compiler.js:491:19)
           at onCompiled (/tmp/build_8801e356/node_modules/webpack/lib/Compiler.js:278:9)
           at /tmp/build_8801e356/node_modules/webpack/lib/Compiler.js:681:15
           at AsyncSeriesHook.eval [as callAsync] (eval at create (/tmp/build_8801e356/node_modules/tapable/lib/HookCodeFactory.js:33:10), <anonymous>:6:1)
           at AsyncSeriesHook.lazyCompileHook (/tmp/build_8801e356/node_modules/tapable/lib/Hook.js:154:20)
           at /tmp/build_8801e356/node_modules/webpack/lib/Compiler.js:678:31
           at AsyncSeriesHook.eval [as callAsync] (eval at create (/tmp/build_8801e356/node_modules/tapable/lib/HookCodeFactory.js:33:10), <anonymous>:6:1)
           at AsyncSeriesHook.lazyCompileHook (/tmp/build_8801e356/node_modules/tapable/lib/Hook.js:154:20)
           at /tmp/build_8801e356/node_modules/webpack/lib/Compilation.js:1423:35
           at AsyncSeriesHook.eval [as callAsync] (eval at create (/tmp/build_8801e356/node_modules/tapable/lib/HookCodeFactory.js:33:10), <anonymous>:6:1)
           at AsyncSeriesHook.lazyCompileHook (/tmp/build_8801e356/node_modules/tapable/lib/Hook.js:154:20)
           at /tmp/build_8801e356/node_modules/webpack/lib/Compilation.js:1414:32
           at eval (eval at create (/tmp/build_8801e356/node_modules/tapable/lib/HookCodeFactory.js:33:10), <anonymous>:14:1)
           at process.processTicksAndRejections (node:internal/process/task_queues:105:5) {
         opensslErrorStack: [
           'error:03000086:digital envelope routines::initialization error',
           'error:0308010C:digital envelope routines::unsupported'
         ],
         library: 'digital envelope routines',
         reason: 'unsupported',
         code: 'ERR_OSSL_EVP_UNSUPPORTED'
       }
```

✅ add `NODE_OPTIONS=--openssl-legacy-provider` to the Heroku config: `heroku config:set NODE_OPTIONS=--openssl-legacy-provider`.

The `assets:precompile` task forced me to upgrade Node.js to a newer version, which in turn caused the `compression-webpack-plugin` to fail. The error message indicates that the OpenSSL version used by Node.js does not support certain cryptographic operations required by the plugin. Setting the `NODE_OPTIONS` environment variable to `--openssl-legacy-provider` allows it to work with the legacy OpenSSL provider. In the future, I plan to upgrade the `compression-webpack-plugin` to a version that supports the new OpenSSL version, but for now, this workaround is sufficient. Current version of `compression-webpack-plugin` is `11.1.0` but the app has installed `4.0.1`. Even though, the previous upgrade was a few years ago. The number of releases in between is scary. JavaScript ecosystem is a nightmare 😢.

---

Eventually, assets got precompiled successfully. Hooray! 🎉 Switchig back to the failed tests.

---

💣 `ArgumentError: wrong number of arguments (given 1, expected 0)` on scopes in models

✅ change `scope :something, ->(from:, to:) { where(from:, to:) }` in several models to `scope :something, ->(kwargs = {}) { where(**kwargs) }`.

To be honest, I don't fully understand why it was failing. But it seems that the issue was in uncompatibility of Ruby 3.4.4 and Rails 6.1. Note, Rails 6.1 doesn't maintain Ruby 3.4 compatibility. I consider this fix as a temporary workaround. When I upgrade Rails to 7.2, I revisit this code and refactor it properly.

Note: it turned out AI was too helpful here. Since there were several places in the codebase with this issue, I simply asked it to fix them all. I used VS Code with GitHub Copilot for that.

Unfortunately, AI is mostly useless when it comes to Ruby/Rails upgrades in general. But it’s quite handy for repetitive, monotonous tasks like this one.

---
💣 `'Regexp#initialize': wrong number of arguments (given 3, expected 1..2) (ArgumentError)`

✅ change `Regexp.new('...', nil, 'n')` to `Regexp.new('...', Regexp::FIXEDENCODING | Regexp::NOENCODING)`.

New Ruby has changes in the `Regexp` class, which caused this error. I personally never use `Regexp.new` for regexps. I don't know why it was used in the project like that. But it was failing, so I fixed it. I must admit, it was pretty tricky to figure which parameters the new way of initializing `Regexp` accepts. I had to check Ruby sources for to come up with this solution. And surprise - AI was not helpful here at all 😜.

---
💣 `ArgumentError: wrong number of arguments (given 1, expected 0)` coming somehwere from `actionview` and `actionpack`.

✅ monkey-patch

```ruby
# frozen_string_literal: true

module ActionDispatch
  module Routing
    module UrlFor
      def initialize(*args)
        @_routes = nil
        super(*args)
      end
    end
  end
end

module ActionController
  class Metal
    def initialize(*_args)
      @_request = nil
      @_response = nil
      @_routes = nil
      super()
    end
  end
end

module ActionView
  module Layouts
    def initialize(*_args)
      @_action_has_layout = true
      super()
    end
  end
end
```

At this moment I thought it was incompatibility between Ruby 3.4.4 and Rails 6.1. Even created a [discussion](https://www.reddit.com/r/rails/comments/1l77bri/rails_6_compatibility_with_ruby_34/) on Reddit. But later I found out that it was actually a problem with `dry-auto_inject` gem. See more details in the [comment](https://github.com/dry-rb/dry-auto_inject/issues/80#issuecomment-2968324620) I left in the reported issue. Later, I removed those monkey-patches and replaced the auto-injection with an explicit class initialization. Fortunately, the project had only one controller that used auto-injection, so it was not a big deal. Again, AI is completely useless here. It generates some crazy fixes that don't work at all. I had to figure it out myself.

---

Ok, tests are passing, assets are precompiled, Rails console works, Rails server starts without errors, and Sidekiq starts without issues. I can now deploy the app to Heroku.

Moving on to the next step - upgrading Rubucop.

---
💣 I upgrade Rubocop and receive a lot of violations with the message `RSpec/BeEq: Prefer be over eq` in a line like this `expect(some_value).to eq(expected_value)`

✅ disable `RSpec/BeEq` cop in the `.rubocop.yml` file.

I decide not to fix them right now. I would like to have the upgrade task to contain as few changes as possible. Moreover, I have doubts that using `be` instead of `eq` is a good idea. I prefer to use `eq` for equality checks it's been working in this project for 7 years and everything has been fine. Why should we change everything now because someone has a different opinion? I will revisit this later, maybe after the Rails upgrade.

So I disable the `RSpec/BeEq` cop in the `.rubocop.yml` file:

```yaml
RSpec/BeEq:
  Enabled: false
```

---

💣 Some cops are failing with `undefined method 'empty?' for an instance of Integer (NoMethodError)`

✅ Do not use Rubocop v1.76.0.

It turned out the `Lint/EmptyInterpolation` cop was failing not only for me but in general. The issue was reproduciable in Rubocop v1.76.0. The cop checks for empty interpolations like `#{}` and raises an error if it finds one. But in Ruby 3.4, the `empty?` method is not defined for `Integer` and other primitives, which causes the error.

I downgrade Rubocop to the previous version and made a [pull request to the Rubocop team](https://github.com/rubocop/rubocop/pull/14245). It was merged almost immediately, and the fix was released in Rubocop v1.76.1. Kudos to the Rubocop team for their quick response! Moreover, I became 900th contributor of RuboCop - congrats me! 🎉

---

There were some other cops that were failing. To avoid too much changes in the code, I regenerate the `.rubocop_todo.yml` file:

```shell
rubocop --auto-gen-config
```

And push the changes to the repository.

Some developers might argue it's best to fix all the violations now — but I disagree. This kind of effort often wastes time without meaningfully improving code quality or test coverage. So, what's the real benefit? I recommend asking yourself: is it worth it? I prefer the 80/20 rule — 20% of the effort yields 80% of the results. In this case, spending 80% of the effort for a questionable 20% gain just isn't worth it.

Ruby upgrade is done! 🎉
