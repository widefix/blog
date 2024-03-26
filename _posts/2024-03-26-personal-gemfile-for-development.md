---
layout: post
title: "Personal Gemfile for development"
headline: "Customize your Gemfile for development"
modified: 2024-03-26 16:04:28 +0100
description: "Learn how to customize the Gemfile for your development comfort without forcing others to use your opinionated gems."
tags: [bundler, ruby]
featured_post: false
toc: true
image: comfort-desk.jpg
---

I want to use [actual_db_schema](https://github.com/widefix/actual_db_schema) in my development process. My colleagues are against it. They say that solving the same problem this gem solves can be done by other means. But I don't want to use their solution as it doesn't improve my development process. I got used to `actual_db_schema`. It makes my workflow so comfortable that I don't accept their solutions. I also don't want to force them using `actual_db_schema`.

What should I do if installing this gem requires changes in the Gemfile? Is it a dead-end? It turned out that it's not. Keep reading to learn how to overcome this obstacle.

## Configure the gem not to run

If you persuaded your colleagues and they agreed to install the gem, then accept my congratulations! You can install the gem by modifying Gemfile and then configuring it so that it doesn't run for anyone by default. But for you, it will run.

Here is how you can do it. Add the gem to Gemfile in development group and install it with bundle. Then add the following initializer:

```ruby
# config/initializers/actual_db_schema.rb
ActualDbSchema.config[:enabled] = ENV['ACTUAL_DB_SCHEMA'] == 'true'
```

Now, if the environment variable `ACTUAL_DB_SCHEMA` is set to `true` the gem will do its job. By default it's not defined for anyone. So the gem won't work for them. But you can define this variable in your shell profile or in the `.env` file.

> While the solution is related to only one gem, you can use it for any other gem. The only requirement for other gems is that they have similar facilities - a configuration option to enable/disable the gem.

While this solution is good, your colleagues may not like that the changes to Gemfile were committed. This is usually the case, and this is okay. Don't worry! There is a solution for this scenario. Keep reading.

## Local Gemfile

I turned out that you can have a local Gemfile. This file is not committed to the repository. It's used only by you. You can use it to install gems that you want to use in your development process but you don't want to force others to use them. This solution is possible because Bundler allows you to specify the path to the Gemfile.

Here is how you can do it. Create a file named `Gemfile.local` in the root of your project. Add the following content to it:

```ruby
eval_gemfile 'Gemfile'

gem 'actual_db_schema'
```

Now, install the gem with the following command:

```bash
BUNDLE_GEMFILE=Gemfile.local bundle install
```

This command will install the gem only for you. The changes in the Gemfile are not committed. The gem is not installed for anyone else. You can use this approach for any other gem you want to use in your development process. Don't forget to add the `Gemfile.local` and `Gemfile.local.lock` to the `.gitignore` file.

> The solution is not limited to the `actual_db_schema` gem. You can use it for any other gem you want to use in your development process but you don't want to force others to use them.


This is the full checklist of the steps you need to follow to install a gem for your development process without forcing others to use it:
- Add these lines to `.gitignore`:

```
Gemfile.local
Gemfile.local.lock
```

- Create the `Gemfile.local` file with the following content:

```ruby
eval_gemfile 'Gemfile'

# add your local gems here
```

- Define the environment variable in your shell profile or in the `.env` file:

```bash
export BUNDLE_GEMFILE=Gemfile.local
```

- Install the gem with the following command:

```bash
bundle install
```

- Enjoy the gem in your development process.

- If you want to commit changes into the original Gemfile, you should unset the `BUNDLE_GEMFILE` environment variable or temprorary set it to the original Gemfile:

```bash
unset BUNDLE_GEMFILE
```

or

```bash
export BUNDLE_GEMFILE=Gemfile
```

or without modifying the shell profile:

```bash
BUNDLE_GEMFILE=Gemfile bundle install
```

## Conclusion

Don't be afraid to use the gems that improve your development process. You can use them without forcing others to use them. The solutions I described in this article will help you to achieve this goal. Use them and enjoy the gems that make your workflow more comfortable. Share this solution with others who may need it. They will appreciate it.
