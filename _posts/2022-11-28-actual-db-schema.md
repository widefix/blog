---
layout: post
title: "Keep DB schema clean and consistent between branches"
modified: 2022-11-28 00:41:06 +0300
description: "Learn how to keep DB schema clean and consistent between branches while develop a Rails application"
tags: [rails, migrations]
comments: true
share: true
image: actual_db_schema.jpg
---

Switching between branches with migrations run for a Rails application causes the DB inconsistent.
Eventually, the application starts raising exceptions coming from DB. You start debugging and spend some time on that.
It turns out that some migrations from not merged branches need rollback.
Sounds familiar? Keep reading to see a solution that solves this issue once and forever (well, with some caveats).

### Problem

Consider a typical Rails application development scenario.

In branch A I add a mandatory (not null) field into DB via migration and run it. Then I switch to another branch B.
This branch's code is not aware of that new field.
As the result, the code is failing with an error "null value provided for non-null field".
Moreover, DB rake tasks generate a diff in `schema.rb` that's not relevant to the current branch.
I can switch to branch A and roll back the not needed migration, but I need to remember that branch. That also wastes my time.

An example of an exception that starts raising in the application "spontaneously":

```ruby
ActiveRecord::NotNullViolation:
   PG::NotNullViolation: ERROR:  null value in column "log" of relation "check_results" violates not-null constraint
   DETAIL:  Failing row contains (8, 46, success, 2022-10-16 21:47:21.07212, 2022-10-16 21:47:21.07212, null).
```

### Solution

What if we have a tool that looks after run migrations outside the current branch and rolls them back automatically?
It would save significant time.

These thoughts made us build this tool. It's [open sourced](https://github.com/widefix/actual_db_schema) and ready for your usage.

All you need is just to put it into your Gemfile and run bunle install:

```ruby
group :development do
  gem "actual_db_schema"
end
```

```shell
$ bundle install
```

From now on, it will try to revert all migrations that are not related to the current branch every time when you run `rails db:migrate`
(or any other Rake task with `db:schema:dump` dependency).

How does it understand which migration should revert? Simply, it collects all run migrations within `tmp` folder.
Knowing the difference between migrations that are related to the current branch (kept inside `db/migrate` folder)
and actually run (kept inside `tmp` folder), it rolls the unrelated migrations back.

### Conclusion

All seems well, but this solution has one caveat. It assumes the migrations are reversible.
Unreversible migrations won't roll back. Handle such situations by hand.

The last item can be a pain point. Fortunately, most migrations are reversible. Hence, still this tool can save much of the dev time.

[Your feedback and questions are always welcomed](https://github.com/widefix/actual_db_schema/discussions).
