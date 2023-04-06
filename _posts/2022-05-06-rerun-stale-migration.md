---
layout: post
title: "Rerun stale migration in Rails"
modified: 2022-05-06 00:41:06 +0300
description: "Figure out how to apply a migration that has already run and the standard rake migration-related tasks don't work."
tags: [rails, migrations]
image: rerun-stale-migration.jpg
toc: true
---

If you are searching for a way to simply rerun a Rails migration, you can use the command `rails db:migrate:redo VERSION=xxxxxxx` or just `rails db:migrate:redo` to rerun the last migration. However, this post is not about that. It is about the case when this command does not work.

## What is a stale Rails schema migration

Consider the following scenario. You are reviewing a pull request (PR) of your colleague.
That PR has a migration that adds a new table into the DB.
You run that migration to test the PR. The migration creates `settings` table.
You go to another branch and continue your work. But you've forget to reverse the migration so that it doesn't mess up your local DB state.
Later, the PR gets this table renamed to `user_settings`. Finally, it gets merged.

Then you update the main branch and run migrations. Surprisingly, you've got changes in `schema.rb`.
Git shows that it wants to add `settings` and remove `user_settings` table.
You realize that you've run the migration that's kinda stale now.
You try to roll this migration back with `rails db:migrate:down VERSION=20220505072316` command. No luck:

```ruby
ActiveRecord::StatementInvalid: PG::UndefinedTable: ERROR:  table "user_settings" does not exist
: DROP TABLE "user_settings"
```

Dead-end? See how to cope with it.

## How Rails knows which migration is already run

Rails has a special table in DB `schema_migrations` that allows to understand which migrations are already run.
Look at its structure inside DB console (jump into it with `rails db` command or use any other DB client).
This is the description of this table inside PostgreSQL:

```sql
~# \d schema_migrations
                 Table "public.schema_migrations"
 Column  │          Type          │ Collation │ Nullable │ Default
═════════╪════════════════════════╪═══════════╪══════════╪═════════
 version │ character varying(255) │           │ not null │
Indexes:
    "unique_schema_migrations" UNIQUE, btree (version)
```

Whenever you run migration it inserts a new row into this table with column `version` equal to the timestamp of the migration file.
For example, a migration inside file `20220505072316_create_settings.rb` inserts row with `version=20220505072316`.

Next time when you run migrations Rails checks if that migration file timestamp is already inside `schema_migrations` table.
If it's not there, it applies the migration, otherwise skips it. That way `rails db:migrate` command guarantees idempotency.

## How to get the stale Rails migration fixed

That knowledge gives us a glue on what to do. If delete that migration timestamp from `schema_migrations` we can run it again.
That will add `user_settings` table but won't delete the stale `settings` table. But that's not a big deal - we can do that manually in the DB console.
Once we do that `rails db:migrate` command won't generate any diff anymore.

Run these commands within the DB console:

```sql
delete from schema_migrations where version = '20220505072316';
drop table settings;
```

Run `rails db:migrate` and make sure there are no changes on your `schema.rb`.

## How to see if a migration is run

It's time for some useful tip. Rails has a built-in rake task that shows status for all migrations - `db:migrate:status`.
Run this `rails db:migrate:status` in your terminal from the Rails application folder and you will see something like that:

```ruby
database: myapp_development

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20220923211114  Initial
  down    20230330161714  Create projects
```

After running the `rails db:migrate:status` command on my pet project, the output displayed two migrations along with their corresponding statuses. When a migration has a status of `up`, it means that it has already been executed. Conversely, when the status is `down`, it indicates that the migration has not been executed yet. If you run `rails db:migrate`, any migrations with a status of `down` will be executed.

## How to avoid getting stale migrations

Not long ago, I implemented a solution aimed at automating tasks to prevent falling into the trap of stale migrations. This is where the [actual_db_schema](https://github.com/widefix/actual_db_schema){:ref="nofollow" target="_blank"} gem comes in. Please feel free to install and use it, and your feedback would be greatly appreciated. You can find more information about this gem in the Keep DB schema clean and consistent between branches](https://blog.widefix.com/actual-db-schema/) article.
