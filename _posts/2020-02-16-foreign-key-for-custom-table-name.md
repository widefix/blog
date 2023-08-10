---
layout: post
title: "Rails migration for belongs_to association with custom table name"
modified: 2020-02-16 00:41:06 +0300
description: "Write a Rails migration for a belongs_to association with different column name or custom table name."
tags: [ruby, rails, active_record, migrations]
comments: true
image: belongs_to_migration.jpg
toc: true
---

**TL;DR:** Provide `to_table` option like that `foreign_key: {to_table: :<table_name>}`.

## Generate migration for belongs_to association

It might be not obviuos how to write a Rails migration for a `belongs_to` association that's joined to a not corresponding to the association name. Read this post to see how to do that.

Imagine the following scenario:
- There is a `User` model in the system already.
- We need to add `Payment` model.
- `Payment` should belong to a `receiver` (business name), that's `User` (the model).

In the code it looks like that:

```ruby
class User < ApplicationRecord
end

class Payment < ApplicationRecord
  belongs_to :receiver, class_name: 'User'
end
```

We generate this model using the built in Rails [generator](https://edgeguides.rubyonrails.org/active_record_migrations.html#model-generators){:ref="nofollow" target="_blank"}:

```shell
rails g model payment receiver:references
```

It also generates this migration to create the corresponding table in the database:

```ruby
class CreatePayments < ActiveRecord::Migration[6.0]
  def change
    create_table :payments do |t|
      t.belongs_to :receiver, null: false, foreign_key: true
      t.timestamps
    end
  end
end
```

## The generated migration might not work

But `rake db:migrate` run produces the following error:

```
PG::UndefinedTable: ERROR:  relation "receivers" does not exist
```

From the error message, it's clear that the migration tries to add a foreign key for a not existing table named `receivers`. This name is derived from the `belongs_to` association name provided within the migration `:receiver`. The corresponding table name for it is `receivers`. This is where this name came from. And there is nothing wrong with that because in most cases we have a corresponding table name defined to a `belongs_to` association. But in our case, there is no `receivers` table. We want the `users` table used instead. Also, we want the column name still correspond to the association name that's `receiver_id`.

## Use to_table of foreign_key option

Unfortunately, the official Rails documentation doesn't tell how to write the migration for this scenario (later, I improved it in this [PR](https://github.com/rails/rails/pull/38469){:ref="nofollow" target="_blank"}). I checked Rails code and found a solution there. Just specify the option `foreign_key: {to_table: :users}` as below:

```ruby
class CreatePayments < ActiveRecord::Migration[6.0]
  def change
    create_table :payments do |t|
      t.belongs_to :receiver, null: false, foreign_key: {to_table: :users}
      t.timestamps
    end
  end
end
```

Now the migration runs without failures and produces the desired result. It creates the `payments` table with the `receiver_id` column and the foreign key points to the joined `users` table.

## Afterwards

To summarize, for a custom joined table or column name (that's the same scenario) of `belongs_to` migration use `foreign_key: {to_table: :users}` like in the example above.

Based on this investigation, I created this [PR](https://github.com/rails/rails/pull/38469){:ref="nofollow" target="_blank"} to improve the documentation.

Thanks to everyone who supported it and made this merge so fast!

