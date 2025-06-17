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

<a id="issue-1" href="#issue-1">💣 issue 1 🔗</a>

```ruby
uninitialized constant GraphQL::Compatibility::ExecutionSpecification::SpecificationSchema::OpenStruct
```

✅ add `require 'ostruct'` in `config/application.rb`.

New Ruby no longer loads `OpenStruct` (and some more standard libraries) by default.

<a id="issue-2" href="#issue-2">💣 issue 2 🔗</a>

```ruby
uninitialized constant ActiveSupport::LoggerThreadSafeLevel::Logger
```

✅ add `require 'logger'` in `config/application.rb`.

New Ruby no longer loads `Logger` by default.

<a id="issue-3" href="#issue-3">💣 issue 3 🔗</a>

```
Bundler::GemRequireError:
  There was an error while trying to load the gem 'bootstrap'.
  Gem Load Error is: bootstrap-rubygem requires a Sass engine. Please add dartsass-sprockets, sassc-rails, dartsass-rails or cssbundling-rails to your dependencies.
```
✅ add `sassc-rails` gem to the `Gemfile`.

The project has `bootstrap` gem. Even though it's useless since the frontend is now a separate React app, I decide to keep it for now. Removing the legacy code is a separate task, and I don't want to mix it with the Ruby upgrade.

<a id="issue-4" href="#issue-4">💣 issue 4 🔗</a>

```
Bundler::GemRequireError:
  There was an error while trying to load the gem 'sidekiq-cron'.
  Gem Load Error is: cannot load such file -- sidekiq/util
  Backtrace for gem load error is:
```

✅ upgrade `sidekiq-cron` gem to the latest version.


<a id="issue-5" href="#issue-5">💣 issue 5 🔗</a>

```
TSort::Cyclic:
  topological sort failed: [...a long list of output...]
```

✅ removing `dartsass-sprockets` and `dartsass-rails` from the `Gemfile`.

Neither dart, nor sass engines are used in the project, so I remove them to avoid the cyclic dependency error. The gems were added by the recommendation of the `bootstrap` gem. But those gems are not needed for the project, so I remove them.



At this point the tests started to run, not all of them passed, but at least I could see the progress. I leave the tests fixing for later and move on to the next step - assets precompilation. On that step I encountered the following issues.


<a id="issue-6" href="#issue-6">💣 issue 6 🔗</a>

```ruby
LoadError: cannot load such file -- drb (LoadError)
```

✅ add gem `drb` to the `Gemfile`.

New Ruby no longer loads `drb` by default, but it is required by the `rails` gem for assets precompilation.


<a id="issue-7" href="#issue-7">💣 issue 7 🔗</a>

```ruby
error Command "build:css" not found.
```

✅ remove `cssbundling-rails` gem from the `Gemfile`.

The `cssbundling-rails` gem is not used in the project, so I remove it to avoid the error. The project uses `sassc-rails` for CSS processing, so I don't need `cssbundling-rails`. This gem was also added by the recommendation of the `bootstrap` gem.


<a id="issue-8" href="#issue-8">💣 issue 8 🔗</a>

Assets precompilation failed on Heroku with the following error:

<br>
<details>
<summary>[webpack-cli] Error: error:0308010C:digital envelope routines::unsupported - click to expand!</summary>

<div>
<pre><code>

[webpack-cli] Error: error:0308010C:digital envelope routines::unsupported
           at new Hash (node:internal/crypto/hash:79:19)
           at Object.createHash (node:crypto:139:10)
           at CompressionPlugin.taskGenerator (/tmp/build_8801e356/node_modules/compression-webpack-plugin/dist/index.js:163:38)
           at taskGenerator.next (&lt;anonymous&gt;)
           at /tmp/build_8801e356/node_modules/compression-webpack-plugin/dist/index.js:216:49
           at CompressionPlugin.runTasks (/tmp/build_8801e356/node_modules/compression-webpack-plugin/dist/index.js:236:9)
           at /tmp/build_8801e356/node_modules/compression-webpack-plugin/dist/index.js:270:18
           at _next0 (eval at create (/tmp/build_8801e356/node_modules/tapable/lib/HookCodeFactory.js:33:10), &lt;anonymous&gt;:37:17)
           at eval (eval at create (/tmp/build_8801e356/node_modules/tapable/lib/HookCodeFactory.js:33:10), &lt;anonymous&gt;:53:1)
           at WebpackAssetsManifest.handleEmit (/tmp/build_8801e356/node_modules/webpack-assets-manifest/src/WebpackAssetsManifest.js:486:5)
           at AsyncSeriesHook.eval [as callAsync] (eval at create (/tmp/build_8801e356/node_modules/tapable/lib/HookCodeFactory.js:33:10), &lt;anonymous&gt;:49:1)
           at AsyncSeriesHook.lazyCompileHook (/tmp/build_8801e356/node_modules/tapable/lib/Hook.js:154:20)
           at Compiler.emitAssets (/tmp/build_8801e356/node_modules/webpack/lib/Compiler.js:491:19)
           at onCompiled (/tmp/build_8801e356/node_modules/webpack/lib/Compiler.js:278:9)
           at /tmp/build_8801e356/node_modules/webpack/lib/Compiler.js:681:15
           at AsyncSeriesHook.eval [as callAsync] (eval at create (/tmp/build_8801e356/node_modules/tapable/lib/HookCodeFactory.js:33:10), &lt;anonymous&gt;:6:1)
           at AsyncSeriesHook.lazyCompileHook (/tmp/build_8801e356/node_modules/tapable/lib/Hook.js:154:20)
           at /tmp/build_8801e356/node_modules/webpack/lib/Compiler.js:678:31
           at AsyncSeriesHook.eval [as callAsync] (eval at create (/tmp/build_8801e356/node_modules/tapable/lib/HookCodeFactory.js:33:10), &lt;anonymous&gt;:6:1)
           at AsyncSeriesHook.lazyCompileHook (/tmp/build_8801e356/node_modules/tapable/lib/Hook.js:154:20)
           at /tmp/build_8801e356/node_modules/webpack/lib/Compilation.js:1423:35
           at AsyncSeriesHook.eval [as callAsync] (eval at create (/tmp/build_8801e356/node_modules/tapable/lib/HookCodeFactory.js:33:10), &lt;anonymous&gt;:6:1)
           at AsyncSeriesHook.lazyCompileHook (/tmp/build_8801e356/node_modules/tapable/lib/Hook.js:154:20)
           at /tmp/build_8801e356/node_modules/webpack/lib/Compilation.js:1414:32
           at eval (eval at create (/tmp/build_8801e356/node_modules/tapable/lib/HookCodeFactory.js:33:10), &lt;anonymous&gt;:14:1)
           at process.processTicksAndRejections (node:internal/process/task_queues:105:5) {
         opensslErrorStack: [
           'error:03000086:digital envelope routines::initialization error',
           'error:0308010C:digital envelope routines::unsupported'
         ],
         library: 'digital envelope routines',
         reason: 'unsupported',
         code: 'ERR_OSSL_EVP_UNSUPPORTED'
       }

</code></pre>
</div>
</details>

✅ add `NODE_OPTIONS=--openssl-legacy-provider` to the Heroku config: `heroku config:set NODE_OPTIONS=--openssl-legacy-provider`.

The `assets:precompile` task forced me to upgrade Node.js to a newer version, which in turn caused the `compression-webpack-plugin` to fail. The error message indicates that the OpenSSL version used by Node.js does not support certain cryptographic operations required by the plugin. Setting the `NODE_OPTIONS` environment variable to `--openssl-legacy-provider` allows it to work with the legacy OpenSSL provider. In the future, I plan to upgrade the `compression-webpack-plugin` to a version that supports the new OpenSSL version, but for now, this workaround is sufficient. Current version of `compression-webpack-plugin` is `11.1.0` but the app has installed `4.0.1`. Even though, the previous upgrade was a few years ago. The number of releases in between is scary. JavaScript ecosystem is a nightmare 😢.



Eventually, assets got precompiled successfully. Hooray! 🎉 Switchig back to the failed tests.



<a id="issue-9" href="#issue-9">💣 issue 9 🔗</a>

I receive these errors on some scopes defined in the models:

```ruby
ArgumentError: wrong number of arguments (given 1, expected 0)
```

✅ change `scope :something, ->(from:, to:) { where(from:, to:) }` in several models to `scope :something, ->(kwargs = {}) { where(**kwargs) }`.

To be honest, I don't fully understand why it was failing. But it seems that the issue was in uncompatibility of Ruby 3.4.4 and Rails 6.1. Note, Rails 6.1 doesn't maintain Ruby 3.4 officially. I consider this fix as a temporary workaround. When I upgrade Rails to 7.2, I revisit this code and refactor it properly.

Note: it turned out AI was too helpful here. Since there were several places in the codebase with this issue, I simply asked it to fix them all. I used VS Code with GitHub Copilot for that.

Unfortunately, AI is mostly useless when it comes to Ruby/Rails upgrades in general. But it’s quite handy for repetitive, monotonous tasks like this one.


<a id="issue-10" href="#issue-10">💣 issue 10 🔗</a>

```ruby
'Regexp#initialize': wrong number of arguments (given 3, expected 1..2) (ArgumentError)
```

✅ change `Regexp.new('...', nil, 'n')` with `Regexp.new('...', Regexp::FIXEDENCODING | Regexp::NOENCODING)`.

New Ruby has changes in the `Regexp` class, which caused this error. I personally never use `Regexp.new` for regexps. I don't know why it was used in the project like that. But it was failing, so I fixed it. I must admit, it was pretty tricky to figure which parameters the new way of initializing `Regexp` accepts. I had to check Ruby sources for to come up with this solution. And surprise - AI was not helpful here at all 😜.


<a id="issue-11" href="#issue-11">💣 issue 11 🔗</a>

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

Ok, tests are passing, assets are precompiled, Rails console works, Rails server starts without errors, and Sidekiq starts without issues. I can now deploy the app to Heroku.

Moving on to the next step - upgrading Rubucop.


<a id="issue-12" href="#issue-12">💣 issue 12 🔗</a>

I upgrade Rubocop and receive a lot of violations with the message `RSpec/BeEq: Prefer be over eq` in a line like this `expect(some_value).to eq(expected_value)`.

✅ disable `RSpec/BeEq` cop in the `.rubocop.yml` file.

I decide not to fix them right now. I would like to have the upgrade task to contain as few changes as possible. Moreover, I have doubts that using `be` instead of `eq` is a good idea. I prefer to use `eq` for equality checks it's been working in this project for 7 years and everything has been fine. Why should we change everything now because someone has a different opinion? I will revisit this later, maybe after the Rails upgrade.

So I disable the `RSpec/BeEq` cop in the `.rubocop.yml` file:

```yaml
RSpec/BeEq:
  Enabled: false
```



<a id="issue-13" href="#issue-13">💣 issue 13 🔗</a>

Some cops are failing with `undefined method 'empty?' for an instance of Integer (NoMethodError)`.

✅ Do not use Rubocop v1.76.0.

It turned out the `Lint/EmptyInterpolation` cop was failing not only for me but in general. The issue was reproduciable in Rubocop v1.76.0. The cop checks for empty interpolations like `#{}` and raises an error if it finds one. But in Ruby 3.4, the `empty?` method is not defined for `Integer` and other primitives, which causes the error.

I downgrade Rubocop to the previous version and made a [pull request to the Rubocop team](https://github.com/rubocop/rubocop/pull/14245). It was merged almost immediately, and the fix was released in Rubocop v1.76.1. Kudos to the Rubocop team for their quick response! Moreover, I became 900th contributor of RuboCop - congrats me! 🎉



There were some other cops that were failing. To avoid too much changes in the code, I regenerate the `.rubocop_todo.yml` file:

```shell
rubocop --auto-gen-config
```

And push the changes to the repository.

Some developers might argue it's best to fix all the violations now — but I disagree. This kind of effort often wastes time without meaningfully improving code quality or test coverage. So, what's the real benefit? I recommend asking yourself: is it worth it? I prefer the 80/20 rule — 20% of the effort yields 80% of the results. In this case, spending 80% of the effort for a questionable 20% gain just isn't worth it.

Ruby upgrade is done! 🎉

## My log of upgrading Rails

Now that Ruby is upgraded, I can move on to upgrading Rails. I start by updating the `Gemfile` to use Rails 7.2:

```ruby
gem 'rails', '7.2.2.1'
```

Then I remove the `Gemfile.lock` file and run `bundle install` to generate a new lock file with the updated Rails version and all dependencies compatible with the new Rails version. If some gems were not compatible, I would update them to the latest versions that support Rails 7.2.

This time, I had to update several gems to make them compatible with Rails 7.2. I will list them below, along with the fixes I made.

Note, I have not dived deep into each issue. When I encountered an issue, I simply tried to upgrade to max version compatible with the current stack. In all cases that worked well. If even upgrade didn't help, I would look into the issue more deeply. But in this case, fortunately I didn't have to do that.


<a id="issue-14" href="#issue-14">💣 issue 14 🔗</a>

```
PaperTrail 12.0.0 is not compatible with ActiveRecord 7.2.2.1. We allow PT
contributors to install incompatible versions of ActiveRecord, and this
warning can be silenced with an environment variable, but this is a bad
idea for normal use. Please install a compatible version of ActiveRecord
instead (>= 5.2, < 6.2). Please see the discussion in paper_trail/compatibility.rb
for details.
```

✅ upgrade `paper_trail` gem to 16.0.0.


<a id="issue-15" href="#issue-15">💣 issue 15 🔗</a>

```
Because paranoia >= 2.5.0, < 2.6.3 depends on activerecord >= 5.1, < 7.1
  and rails >= 7.2.2.1, < 8.0.0.beta1 depends on activerecord = 7.2.2.1,
  paranoia >= 2.5.0, < 2.6.3 is incompatible with rails >= 7.2.2.1, < 8.0.0.beta1.
So, because Gemfile depends on rails = 7.2.2.1
  and Gemfile depends on paranoia = 2.6.2,
  version solving has failed.
```

✅ upgrade `paranoia` gem to 3.0.1.


<a id="issue-16" href="#issue-16">💣 issue 16 🔗</a>

<br>
<details>
<summary>ActiveSupport::Dependencies.reference is deprecated - click to expand!</summary>

<pre><code>
NoMethodError:
  undefined method 'reference' for module ActiveSupport::Dependencies
# ./config/application.rb:12:in '<top (required)>'
# ./config/environment.rb:2:in 'Kernel#require_relative'
# ./config/environment.rb:2:in '<top (required)>'
# ./spec/rails_helper.rb:3:in '<top (required)>'
# ./spec/mailers/mailer_spec.rb:1:in '<top (required)>'
~/.rbenv/versions/3.4.4/lib/ruby/gems/3.4.0/gems/devise-4.7.0/lib/devise.rb:52: warning: already initialized constant Devise::ALL
~/.rbenv/versions/3.4.4/lib/ruby/gems/3.4.0/gems/devise-4.7.0/lib/devise.rb:52: warning: previous definition of ALL was here
~/.rbenv/versions/3.4.4/lib/ruby/gems/3.4.0/gems/devise-4.7.0/lib/devise.rb:53: warning: already initialized constant Devise::CONTROLLERS
~/.rbenv/versions/3.4.4/lib/ruby/gems/3.4.0/gems/devise-4.7.0/lib/devise.rb:53: warning: previous definition of CONTROLLERS was here
~/.rbenv/versions/3.4.4/lib/ruby/gems/3.4.0/gems/devise-4.7.0/lib/devise.rb:54: warning: already initialized constant Devise::ROUTES
~/.rbenv/versions/3.4.4/lib/ruby/gems/3.4.0/gems/devise-4.7.0/lib/devise.rb:54: warning: previous definition of ROUTES was here
~/.rbenv/versions/3.4.4/lib/ruby/gems/3.4.0/gems/devise-4.7.0/lib/devise.rb:55: warning: already initialized constant Devise::STRATEGIES
~/.rbenv/versions/3.4.4/lib/ruby/gems/3.4.0/gems/devise-4.7.0/lib/devise.rb:55: warning: previous definition of STRATEGIES was here
~/.rbenv/versions/3.4.4/lib/ruby/gems/3.4.0/gems/devise-4.7.0/lib/devise.rb:56: warning: already initialized constant Devise::URL_HELPERS
~/.rbenv/versions/3.4.4/lib/ruby/gems/3.4.0/gems/devise-4.7.0/lib/devise.rb:56: warning: previous definition of URL_HELPERS was here
~/.rbenv/versions/3.4.4/lib/ruby/gems/3.4.0/gems/devise-4.7.0/lib/devise.rb:59: warning: already initialized constant Devise::NO_INPUT
~/.rbenv/versions/3.4.4/lib/ruby/gems/3.4.0/gems/devise-4.7.0/lib/devise.rb:59: warning: previous definition of NO_INPUT was here
~/.rbenv/versions/3.4.4/lib/ruby/gems/3.4.0/gems/devise-4.7.0/lib/devise.rb:62: warning: already initialized constant Devise::TRUE_VALUES
~/.rbenv/versions/3.4.4/lib/ruby/gems/3.4.0/gems/devise-4.7.0/lib/devise.rb:62: warning: previous definition of TRUE_VALUES was here
</code></pre>
</details>

✅ upgrade `devise` gem to 4.9.4.


<a id="issue-17" href="#issue-17">💣 issue 17 🔗</a>

During production deployment on Heroku, I receive the following error on the assets precompilation step:

```
Uglifier::Error: Unexpected token: keyword (const). To use ES6 syntax, harmony mode must be enabled with Uglifier.new(:harmony => true)
```

✅ replace `uglifier` gem with `terser` and configure the new js compressor in the environment files:

```ruby
config.assets.js_compressor = :terser # instead of :uglifier used before
```

<a id="issue-18" href="#issue-18">💣 issue 18 🔗</a>

Rails console fails with the following error:

```
~/.rbenv/versions/3.4.4/lib/ruby/site_ruby/3.4.0/bundler/rubygems_integration.rb:215:in 'block (2 levels) in Kernel#replace_gem': can't activate listen (~> 3.5), already activated listen-3.0.8. Make sure all dependencies are added to Gemfile. (Gem::LoadError)
```

✅ upgrade `listen` gem to 3.9.0.

<a id="issue-19" href="#issue-19">💣 issue 19 🔗</a>

```ruby
RuntimeError:
  Attach interfaces using `implements(SomeType)`, not `include(SomeType)`
```

✅ upgrade `graphql` gem to 1.13.25.

At that point all gems were updated to the latest versions compatible with Rails 7.2.

<a id="issue-20" href="#issue-20">💣 issue 20 - Zeitwerk 🔗</a>

Next, I encounter a lot of issues related to code eager loading. Rails 7.2 made zeitwerk the default code loader, which is stricter than the previous classic loader. It requires all classes and modules to be defined in files with matching names and paths. This means that if you have a class `Foo::Bar`, it must be defined in a file `foo/bar.rb`.

Unfortunately, the project has a lot of code that doesn't follow this convention. I could not to come up with any Zeitwerk configuration that would make it work without changing the code. So, I decided to load those failing files manually in an initializer. I created a new initializer file `config/initializers/zeitwerk.rb` and added the following code (note, the code is obfuscated for security reasons):

```ruby
# These are classes that don't follow the current inflection rules, and hence Zeitwerk conventions.
custom_classes = %w[
  AlphaProcessJob
  BetaNotificationMailer
  GammaSyncService
]

# Map underscored file names to class names that don't follow Zeitwerk conventions
mapping = custom_classes.map { |klass| [klass.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase, klass] }.to_h

# Register inflection mapping
Rails.autoloaders.main.inflector.inflect(mapping)

# Ignore specific folders
%w[
  app/modules/foo
  app/modules/bar
  app/modules/baz
].each do |folder|
  Rails.autoloaders.main.ignore(Rails.root.join(folder))
end

# Manually require a few specific files
require Rails.root.join("app/modules/foo/core_update_service.rb")

# Load all Ruby files in nested folders
Dir[Rails.root.join("app/modules/bar/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("app/modules/baz/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("app/modules/shared/**/*.rb")].each { |f| require f }
```

In the inflections config (`config/initializers/inflections.rb` file) the project had some abbreviations configured, like this:

```ruby
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'ALPHA'
  inflect.acronym 'BETA'
  inflect.acronym 'GAMMA'
end
```

Having these inflections, Zeitwerk expects `ALPHAProcessJob` class defined in `alpha_process_job.rb` file. But the current class name in this file is `AlphaProcessJob`. The same applies to some more classes. I don't want to jeopardize the existing code by making the class renames. Especially, when some of these classes are Sidekiq jobs. Renaming job classes could fail the existing jobs in production. When it comes to other files, I just want to mitigate any possible risks. Again, I want Ruby and Rails upgrade to be only an upgrade, but not a refactoring task.

Some folders in the project violate Zeitwerk conventions so badly that neither inflections nor autoloading of these folders doesn't help. For example, the same folder, say `app/modules/foo` has a file `bar.rb` with a class `Bar` (without the required `Foo` namespace!). At the same time, there is another file, say `qux.rb`, in the same folder `app/modules/foo` with a class under the namespace `Foo::Qux`. Crazy stuff! I don't know how it has been working before.

For that reason, I ignore these tricky folders and load the files from these folders manually. Some files needed specific loading order (like class `B` depends on class `A`), so I explicitly required them in the initializer and iterate over the files that depend on base classes like this one with a loop.

If some class is wrapped in a module, Zeitwerk expects the module to be defined in a file with the same name as the module. For example, if you have a class `Foo::Bar`, it must be defined in a file `foo/bar.rb`, it expects `foo.rb` file to have defined `Foo` module/class. The project has several modules missed like that. So, I add the necessary files that define these missed modules. Not a big deal, just a few files.

<a id="issue-21" href="#issue-21">💣 issue 21 🔗</a>


There were a lot of `to_s` methods in the codebase that were failing with the following error:

```ruby
wrong number of arguments (given 1, expected 0) (ArgumentError)
```

✅ change `to_s(:utc)` to `to_fs(:utc)`.

This is a change in Rails 7.2, where `to_s` no longer accepts a format argument. Instead, you should use `to_fs` method for formatting dates and times. I asked AI to fix this issue in the coidebase, and it did a good job.

<a id="issue-22" href="#issue-22">💣 issue 22 🔗</a>

Rails 7 has made some changes on schema.rb. [Read this](https://rubyonrails.org/2022/2/11/this-week-in-rails-rails-7-0-2-schema-versioning-based-on-the-rails-version-and-more-cbcb0592) for more details.

I just regenerate `schema.rb` with `rails db:migrate` and it generates a new schema. The changes I got:

```ruby
| -ActiveRecord::Schema.define(version: 2025_04_29_203724) do
| +ActiveRecord::Schema[7.2].define(version: 2025_04_29_203724) do


| -    t.datetime "created_at", precision: 6, null: false
| +    t.datetime "created_at", null: false

| -    t.datetime "updated_at", null: false
| +    t.datetime "updated_at", precision: nil, null: false
```

And so on. As you see, the schema is now versioned, and the datetime columns have their precision removed.

<a id="issue-23" href="#issue-23">💣 issue 23 🔗</a>

The codebase has several places iterating over ActiveRecord errors like this:

```ruby
errors.each do |attribute, message|
  puts "#{attribute}: #{message}"
end
```

This fails, as instead of attribute and message, it returns an instance of `ActiveModel::Error` class now. So, I change the code to:

```ruby
errors.each do |error|
  puts "#{error.attribute}: #{error.message}"
end
```

Again, AI helped me with that. It identified all places in the codebase where this issue occurred and fixed them. I was surprised how well it worked.

<a id="issue-24" href="#issue-24">💣 issue 24 🔗</

A code like this stopped working:

```ruby
object.errors[:base] << 'Some error message'
```

✅ change it to:

```ruby
object.errors.add(:base, 'Some error message')
```

This is a change in Rails 7.2, where you should use `add` method to add errors to the base attribute. AI was helpful here as well, it found all places in the codebase where this issue occurred and fixed them.

<a id="issue-25" href="#issue-25">💣 issue 25 🔗</a>

`alias_attribute` method stopped working on deleted attributes that are columns of the delegated object.

Say, we have the following code:

```ruby
class User < ApplicationRecord
  belongs_to :address

  delegate :my_column, to: :address

  alias_attribute :new_my_column, :my_column
end
```

It would fail with the following error:

```
User model aliases `my_column`, but `my_column` is not an attribute. Use `alias_method :new_my_column, :my_column` or define the method manually. (ArgumentError)

          raise ArgumentError, "#{self.name} model aliases `#{old_name}`, but `#{old_name}` is not an attribute. " \
```

✅ change `alias_attribute` to the plain Ruby code like this:

```ruby
def new_my_column
  my_column
end
```

Fortunately, there were not many places like this in the codebase, so I fixed them manually. AI suggested not working solution, so I had to come up with my own.

<a id="issue-26" href="#issue-26">💣 issue 26 🔗</a>

PaperTrail stopped working at the deserialization step with errors like this:

```ruby
Psych::DisallowedClass:
        Tried to load unspecified class: Symbol
```

✅ I added the following to the `config/application.rb` file:

```ruby
config.active_record.use_yaml_unsafe_load = true
```

Some changes in YAML deserialization. See more details on StackOverflow [here](https://stackoverflow.com/questions/72970170/upgrading-to-rails-6-1-6-1-causes-psychdisallowedclass-tried-to-load-unspecif).

<a id="issue-27" href="#issue-27">💣 issue 27 🔗</a>

Custom initializers (in `config/initializers` folder) that use some code defined in the `lib` folder started to fail with an error like this:

```ruby
NameError:
  uninitialized constant Foo::Bar
```

✅ I tried to make Zeitwerk load the `lib` folder, but it didn't help. So, I had to require the necessary files in the initializers manually.

```ruby
require 'lib/foo/bar'

...
```

I don't like this solution. But there are not many initializers like this, so I just fixed them manually. Didn't try to use AI here, as I didn't want to waste time on it.

And mostly that's it! 🎉


## First impressions

The code autocompletion in the Rails console is much better now. The suggestions are much faster and more accurate. At first glance, the response time for http requests is much faster on Heroku now. I didn't measure it, but it feels snappier. The changes are not in production yet, so I will measure the performance later and compare the results.

I like Zeitwerk as the default code loader. It is much stricter than the classic loader, but it helps to catch issues early.


## Conclusion

Upgrading Ruby and Rails is a challenging but rewarding task. It requires careful planning, testing, and sometimes a bit of creativity to work around issues. I hope my experience helps you in your own upgrade journey.

AI tools can be helpful, but they are not a silver bullet. They can speed up the process, but you still need to understand the code and the changes you make. I found AI most useful for repetitive tasks, like fixing the same issue in multiple places. But for more complex issues, I had to rely on my own knowledge and experience.

At first, when I started the upgrade I thought that would be a boring task. But it turned out to be quite interesting and challenging. I learned a lot about the codebase and how Rails works under the hood. I also learned a lot about Ruby 3.4 and Rails 7.2.

Following the 20/80 rule, I focused on the most important changes that would yield the most significant benefits. I didn't try to fix every single issue or violation. Instead, I concentrated on the changes that would make the app work with the new Ruby and Rails versions.

Iterative changes helped me to isolate issues and test each change separately. This way, I could ensure that everything works as expected before moving on to the next step. I highly recommend this approach for any upgrade task.

Additionally, I made some contributions to the open-source community by reporting issues and making pull requests to the gems the project has. I think it's important to give back to the community as it makes me involved in something bigger. Have you ever struggled with finding your purpose, maybe with finding your place in the world? I found that contributing to open-source projects helps me feel more connected to the community and gives me a sense of purpose. I encourage you to do the same.
