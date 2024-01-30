---
title: Reconcile app users vs Stripe and prevent financial losses
layout: post
headline: How we reconciled app users with Stripe and prevented financial losses
modified: '2023-12-14 18:23:20 +0100'
description: Read the story of how we managed to prevent financial losses within an app for one of our clients.
tags:
- stripe
- sql
- ruby
- data-analysis
featured_post: false
toc: true
image: reconcile-stripe.jpg
---

## Possible discrepancies in Stripe integrations

Stripe integrations often experience data consistency issues, such as users being on different subscription plans in the app compared to Stripe. This misalignment can lead to lost revenue or jeopardize customer success stories.

For example, a customer may have a premium status within the app, while Stripe shows no active subscription. This type of discrepancy can lead to lost revenue for the business. Another potential issue occurs when a customer overpays. In this case, the customer is on the free plan within the app but has an active subscription to the premium plan in Stripe, jeopardizing the customer success story.

## Stripe integration state of our application

This blog post outlines the approach we took to resolve such issues in our app, which had around 80k users, with 10% on the premium plan. We identified instances of both overpayment and underpayment, which could be attributed to manual data manipulation in Stripe, missing webhooks, or bugs in our system.

## The plan to reconciliate data with Stripe

While we used Ruby for scripting, this solution is universal and can be applied to applications written in other languages like Python, Node.js, Java, Rust, and Go.

Our plan is the following:

1. Fetch all relevant data from Stripe via Stripe REST API. In our case that included all customer entities and their subscriptions.
2. Put the fetched data into our database. To avoid polluting the main database schema, use a separate namespace for these tables. In fact, PostgreSQL refers to this namespace concept as `schema`. The default schema is `public`. We create the `stripe` schema and necessary tables inside it.
3. Analyze the discrepancies using SQL queries. SQL is not only faster and less prone to bugs for this kind of task in terms of data processing but also in development. This means we will obtain results faster with fewer expenses for the business.
4. Configure Metabase for these reports. Metabase is the system we use to write SQL and build reports. Set up notifications for data discrepancies so that we receive alerts about new cases and can react to them as soon as possible. Luckily, it was already set up for this project. The good news is that its setup takes very little time.
5. Schedule the data scraper from Step 1 to run automatically every week.

![Shining plan](/images/shining-plan.jpg)

## Stripe data store preparation

First, we need to create the DB schema along with the Stripe tables. This is the SQL script we used for that:

```sql
create schema stripe;
create table stripe.customers (
  id serial not null,
  stripe_id varchar(250),
  email varchar(250) not null,
  created_in_stripe timestamp,
  description varchar(250),
  metadata jsonb,
  deleted boolean,
  created_at timestamp default current_timestamp,
  updated_at timestamp default current_timestamp
);
create table stripe.subscriptions (
  id serial not null,
  stripe_id varchar(250),
  stripe_customer_id varchar(250),
  plan_id varchar(250),
  status varchar(250),
  created_at timestamp default current_timestamp,
  updated_at timestamp default current_timestamp
);
```

> Inside the Rails app, data migrations could be created for this purpose. However, as we are unsure whether these tables are permanent at the moment, we use SQL and execute it manually on the server.

Our app uses Rails, so it has `ActiveRecord`, and we can point our models to these tables. These are the `ActiveRecord` models we created for our convenience while working with these tables in the Ruby script:

```ruby
class StripeSchema < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :stripe
end

class StripeCustomer < StripeSchema
  self.table_name = :customers
  self.primary_key = :id
end

class StripeSubscription < StripeSchema
  self.table_name = :subscriptions
  self.primary_key = :id

  belongs_to :stripe_customer, foreign_key: :stripe_id
end
```

We have a special folder in the app, `app/scripts`, where we put this kind of ad-hoc code. Later, we use Rails runner to execute them on the production server against the real data. They can also be run locally for testing purposes during script development. This script code was put into `app/scripts/stripe_classes.rb` file.

## The Stripe data scrapper

And this is the script we've come up with:

```ruby
starting_after = nil

loop do
  params = {expand: ['data.subscriptions'], limit: 100}
  params[:starting_after] = starting_after if starting_after

  customers = Stripe::Customer.list(params)

  customers.each do |cus|
    ApplicationRecord.transaction do
      StripeCustomer.create(
        email: cus["email"],
        stripe_id: cus["id"],
        description: cus["description"],
        created_in_stripe: cus["created"] ? Time.zone.at(cus["created"]) : nil,
        metadata: cus["metadata"],
        subscriptions: customer_subscriptions,
        deleted: cus["deleted"]
      )

      cus.subscriptions.each do |sub|
        StripeSubscription.create(
          stripe_customer_id: cus["id"],
          stripe_id: sub["id"],
          plan_id: sub["plan"]["id"],
          status: sub["status"]
        )
      end
    end

    starting_after = cus["id"]
  end
  break if customers.count < 100
end
```

This script fetches all Stripe customers along with their subscriptions. Later, using this data, we can compare it against our app's database and identify any deviations.

We run this script on the server with the [rails runner](https://guides.rubyonrails.org/command_line.html#bin-rails-runner). Its run can take a while. Not to get the process killed with a closed SSH connection to the server, we use [screen](https://www.gnu.org/software/screen/) utility. At least for the first time, we have to run it manually and monitor for any failures. If there are any issues, we fix them. This way, we verify that the script is valid and reliable. Later, we can automate it to run on a schedule. We've collected data on 85k customers and 8.5k subscriptions, and it took around 1 hour. Not bad for this amount of data.

![Collected data from Stripe](/images/data-stripe.jpg)

## Run the script automatically

After some preliminary data analysis and verification of its correctness, we can set up this script to run automatically on the server. We use sidekiq and its extension sidekiq-scheduler for this, as it's already in place. The app also has Rollbar configured to monitor exceptions and errors, so if something goes wrong, we can be notified.

This is the job:

```ruby
class UpdateStripeData
  include Sidekiq::Worker

  require_relative '../../scripts/stripe_classes'

  def perform
    drop_old_data
    record_stripe_data
  end

  private

  def record_stripe_data
    starting_after = nil

    loop do
      params = {expand: ['data.subscriptions'], limit: 100}
      params[:starting_after] = starting_after if starting_after

      customers = Stripe::Customer.list(params)

      customers.each do |cus|
        ApplicationRecord.transaction do
          StripeCustomer.create(
            email: cus["email"],
            stripe_id: cus["id"],
            description: cus["description"],
            created_in_stripe: cus["created"] ? Time.zone.at(cus["created"]) : nil,
            metadata: cus["metadata"],
            subscriptions: customer_subscriptions,
            deleted: cus["deleted"]
          )

          cus.subscriptions.each do |sub|
            StripeSubscription.create(
              stripe_customer_id: cus["id"],
              stripe_id: sub["id"],
              plan_id: sub["plan"]["id"],
              status: sub["status"]
            )
          end
        end

        starting_after = cus["id"]
      end
      break if customers.count < 100
    end
  end

  def drop_old_data
    ActiveRecord::Base.connection.execute(<<~SQL)
      delete from stripe.customers;
      delete from stripe.subscriptions;
    SQL
  end
end
```

And this is the configuration defined in `config/sidekiq_scheduler.yml` to run it every Saturday at 12:00PM in UTC time zone:

```yaml
production:
  update_stripe_data:
    class: UpdateStripeData
    cron: '0 12 * * 6'
```

We chose that time as the servers are less loaded during those hours.

## Analyze Stripe data discrepancies with SQL

We are all set. With the data in place, we can use SQL to identify all deviations. This will involve using common table expression (CTE), views, joins, filters, and aggregation functions.

Note that the script fetches the Stripe data once a week, and it takes around 1 hour to run. Consequently, the app data will always be ahead of the Stripe data. This is crucial to understand because we cannot join the current app data against the cached Stripe data due to this time lag. Therefore, we need the app data snapshot at the moment the script was run.

Creating a real data snapshot is an option, but it would significantly complicate our architectural story. Fortunately, we have Papertrail configured in the app, a gem that stores all changes to users. This means we can reinstall actual data at the moment the script fetched Stripe data was run. The only field of interest for us is `plan_id`. Therefore, we reinstall only this field. To reuse the reinstalled data, we utilize views. These are kind of virtual tables inside SQL but don't store the collected data:

```sql
create view stripe.users_with_actual_plan as (
    with stripe_update as (
        select created_at as ts from stripe.subscriptions limit 1
    ),
    recent_versions as (
        select * from versions where created_at >= (select ts - interval '1 day' from stripe_update)
    ),
    data as (
        select
            u.*,
            coalesce (
                coalesce(
                    coalesce(
                        (substring((vp.object_changes->>'plan_id') from ', (\d+)'))::int,
                        (substring(vp.object from '\nplan_id: (\d+)'))::int
                    ),
                    coalesce(
                        (substring((vf.object_changes->>'plan_id') from '(\d+),'))::int,
                        (substring(vf.object from '\nplan_id: (\d+)'))::int
                    )
                ),
                u.plan_id
            ) as actual_plan_id,
            rank() over (partition by u.id order by vp.created_at desc nulls last, vf.created_at asc) as version_rank
        from users u
        left join stripe.customers c on c.stripe_id = u.stripe_customer_id
        left join recent_versions vp on vp.item_id = u.id and vp.created_at < coalesce(c.created_at, (select ts from stripe_update))
        left join recent_versions vf on vf.item_id = u.id and vf.created_at >= coalesce(c.created_at, (select ts from stripe_update))
    ) select * from data where version_rank = 1
);
 ```

This SQL query might look intimidating, and that's okay. It's not essential for understanding everything here. All you need to know is what it does, and you already have that knowledge. It creates a virtual table of users with the actual `plan_id` that was set just before the script fetched Stripe data.

> One might ask, "How do we end up creating SQL queries that appear so complicated and intimidating?" The answer is simple: through small steps, selecting one field at a time, joining step by step, and eventually combining them into a single query using the CTE construction.

And now, we are ready to join these users with the actual plan data from Stripe.

This time, the SQL looks much easier:

```sql
with stripe_update as (
    select created_at ts from stripe.subscriptions limit 1
)
select u.* from
stripe.users_with_actual_plan u
left join stripe.subscriptions s on s.stripe_customer_id = u.stripe_customer_id
where u.actual_plan_id is not null and u.actual_plan_id not in (6, 121)
    and u.created_at < (select ts from stripe_update)
    and s.id is null
;
```

The plan with ID = 6 is the free plan, and 121 is a technical one used only for internal purposes. Therefore, the entire expression `u.actual_plan_id is not null and u.actual_plan_id not in (6, 121)` indicates that the user is on a paid plan.

We inputted this SQL into Metabase, and this is what it looks like:

![SQL inside Metabase](/images/reported-users.png)

> Optionally, we can configure notifications to be sent even when a new record is added to these results. See the bell icon at the bottom right; it's intended for this purpose.

As we can see, there were 983 instances of user data discrepancies found. It's a significant amount of data.
