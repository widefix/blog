---
layout: post
title: "Multiple schemas support added to ActualDbSchema"
headline: "Multiple schemas support added to ActualDbSchema"
modified: 2025-01-15 19:21:16 +0100
description: "Some description goes here."
tags: [actual_db_schema, rails, rails-development, migrations]
featured_post: false
toc: true
image: actual_db_schema-081.png
---

Good day, everyone! I'm excited to announce the [release of actual_db_schema v0.8.1](https://github.com/widefix/actual_db_schema/releases/tag/v0.8.1)! 🎉 This milestone is particularly special as it focuses entirely on addressing feedback from our valued users. Check out the updates and improvements introduced in this release.

## Rake task added to initialize the gem

Run the following command to generate the default initializer (an optional post-installation step):

```shell
rake actual_db_schema:install
```

> This step is optional and only necessary if you wish to modify the default configuration. If you are already using the gem and have manually created the initializer, it is recommended to back up your `config/initializers/actual_db_schema.rb` file (if it exists) before proceeding.

## DSL for configuring the gem

To make the gem configuration more flexible and reliable, we have introduced a DSL.

Use the following DSL to configure the gem. This will also be generated as a content of `config/initializers/actual_db_schema.rb` by the init command above.

```ruby
ActualDbSchema.configure do |config|
  # Enable the gem.
  config.enabled = Rails.env.development?
  # Disable automatic rollback of phantom migrations.
  # config.auto_rollback_disabled = true
  config.auto_rollback_disabled = ENV["ACTUAL_DB_SCHEMA_AUTO_ROLLBACK_DISABLED"].present?
  # Enable the UI for managing migrations.
  config.ui_enabled = Rails.env.development? || ENV["ACTUAL_DB_SCHEMA_UI_ENABLED"].present?
  # Enable automatic phantom migration rollback on branch switch,
  # config.git_hooks_enabled = true
  config.git_hooks_enabled = ENV["ACTUAL_DB_SCHEMA_GIT_HOOKS_ENABLED"].present?
  # If your application leverages multiple schemas for multi-tenancy, define the active schemas.
  # config.multi_tenant_schemas = -> { ["public", "tenant1", "tenant2"] }
end
```

## Support for multiple database schemas

From now on, the gem is compatible with multi-tenant applications that are using the [apartment gem](https://github.com/influitive/apartment) or similar solutions.

To add support for multiple schemas, define the active schemas in the configuration:

```ruby
ActualDbSchema.configure do |config|
  config.multi_tenant_schemas = -> { ["public", "tenant1", "tenant2"] }
end
```

> By multi-tenant schemas, we refer to schemas that are designated for different tenants within an application. For instance, in a SaaS application, each tenant is assigned its own schema. Although the set of migrations and schema structure remains consistent across all tenants, the data within each schema is isolated, ensuring tenant-specific separation. Check out the [apartment gem](https://github.com/influitive/apartment) for more details.

## The link to Changelog fixed

The [Rubygems.org](https://rubygems.org/gems/actual_db_schema) page now correctly displays the changelog link, which was previously broken.

## Run the git hook on switch branch only

The gem now runs the git hook only when switching branches, ensuring that the rollback process is triggered only when necessary.

This ensures that when you reset a file using `git checkout` in the current branch, the gem hook will no longer run as it previously would. This prevents unnecessary rollbacks and streamlines the development process, making it more efficient and convenient.


## Conclusion

Thanks to the valuable feedback and suggestions from our users, we've made significant improvements to the gem. We believe these updates will enhance your experience with ActualDbSchema, making it an even more powerful tool for your Rails application development.

The next release is already in progress, so stay tuned for more exciting updates!
