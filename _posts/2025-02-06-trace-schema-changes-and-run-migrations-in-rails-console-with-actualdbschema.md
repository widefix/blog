---
layout: post
title: "Trace Schema Changes &amp; Run Migrations in Rails Console with ActualDbSchema"
headline: "Trace Schema Changes &amp; Run Migrations in Rails Console with ActualDbSchema"
modified: 2025-02-06 12:37:00 +0400
description: "Some description goes here."
tags: [actual_db_schema, rails, rails-development, migrations]
featured_post: false
toc: true
image: actual_db_schema-082.jpg
author:
    name: Mane Darbinyan
    github: m-darbinyan
    linkedin: mane-darbinyan
    twitter: ManeDarbinyan
---

Hello, everyone! We're happy to announce the release of ActualDbSchema v0.8.2! 🎉 This release introduces two features that will make your Rails development experience even smoother. Let’s dive into the details!

## Schema Diff with Migration Annotations

Ever stared at the `schema.rb` diff wondering *"Which migration caused this?"* Tracking down the origin of schema changes across multiple migrations can be time-consuming, especially in collaborative environments.

The new `diff_schema_with_migrations` Rake task generates a diff of the `schema.rb` file, annotated with the migrations responsible for each change. This makes it easier to identify which migration introduced a specific schema modification, helping you decide whether to resolve the diff on your own or discuss it with your teammates to determine the next steps.

Here's an example of what the schema diff with migration annotations looks like in action:

![schema_diff](/images/schema_diff.png)

By default, the task uses `db/schema.rb` and `db/migrate` as the schema and migrations paths. You can run it with the following command:

```shell
rake actual_db_schema:diff_schema_with_migrations
```

If your project uses custom paths for the schema or migrations, you can provide them as arguments:

```shell
rake actual_db_schema:diff_schema_with_migrations[path/to/custom_schema.rb, path/to/custom_migrations]
```

> This task also checks for phantom migrations. If phantom migrations were not properly rolled back (due to failure or pending migration), the schema might contain related changes that are missing from the original migrations. These changes are properly detected and included in the schema diff, giving you a more complete and accurate picture of your database history.

## Console Migrations

Sometimes, you need to make quick adjustments to your database schema without creating migration files - whether you’re fixing a corrupted schema, experimenting with indexes, or making quick changes in development. This feature allows you to run the same commands used in migrations directly in the Rails console. 

By default, Console Migrations is disabled. You can enable it in two ways:

**1. Using Environment Variable**

Set the environment variable `ACTUAL_DB_SCHEMA_CONSOLE_MIGRATIONS_ENABLED` to `true`:

```shell
export ACTUAL_DB_SCHEMA_CONSOLE_MIGRATIONS_ENABLED=true
```

**2. Using Initializer**

Add the following line to your initializer file (`config/initializers/actual_db_schema.rb`):

```ruby
config.console_migrations_enabled = true
```

Once enabled, you can run migration commands directly in the Rails console. Here are a few examples:

```ruby
# Create a new table
create_table :posts do |t|
  t.string :title
end

# Add a column
add_column :users, :age, :integer

# Remove an index
remove_index :users, :email

# Rename a column
rename_column :users, :username, :handle
```

## Conclusion

We hope these features help you keep your database schema clean, consistent, and easy to work with. We’re committed to making Rails development more efficient and enjoyable, and your feedback continues to drive these improvements. Give these new features a try and let us know what you think!

Stay tuned for more updates in the next release. Happy coding! 🚀
