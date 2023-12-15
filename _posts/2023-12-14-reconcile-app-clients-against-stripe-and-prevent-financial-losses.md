---
title: Reconcile App Clients against Stripe and Prevent Financial Losses
layout: post
headline: Reconcile your app clients against Stripe to prevent financial losses
modified: '2023-12-14 18:23:20 +0100'
description: Uncover financial discrepancies and prevent losses with Stripe reconciliation. This practical guide is tailored for startups and established businesses alike.
tags:
- stripe
- sql
- ruby
featured_post: false
toc: true
image: reconcile-stripe.jpg
---

## Possible discrepancies in Stripe integrations

Stripe integrations often have data consistency issues, such as users being on different subscription plans in the app and Stripe. This can result in lost revenue or jeopardize customer success stories.

For example, a customer is premium within the app, while Stripe has no active subscription. This type of discrepancy can result in lost revenue for the business. Another potential error is when a customer overpays. In this case, the customer is on the free plan within the app while having an active subscription to the premium plan in Stripe. This can jeopardize the customer success story.

## Stripe integration state of our application

In this blog post, we will discuss the approach we took to resolve this kind of issues in our app. The app had around 80k users. Out of which 10% are on the premium plan. We know that some of them are overpaying while others are underpaying. This could be due to manual data manipulation in Stripe, missing webhooks, or bugs in our system.

## The plan to reconciliate data with Stripe

While we used Ruby for scripting, this solution is universal and can be applied to applications written in other languages, such as Python, Node.js, Java, Rust, and Go.

Our plan is the following:

1. Fetch all relevant data from Stripe, e.g. customers and their subscriptions.
2. Put it into our DB. Not to pollute the main DB schema, we will use a separate namespace for these tables. In fact, PostgreSQL calls these namespace concept as `schema`. The default schema is `public`. We create `stripe` schema and their necessary tables.
3. Analyze the discrepancies using SQL.
4. Configure Metabase for the new reports. Metabase is the system we use to write SQL and build reports. Set notifications about data discrepancies so that we receive about new cases and react on them as soon as possible.
5. Optionally, schedule the data scrapper from p.1 to run automatically every week.

![Shining plan](/images/shining-plan.jpg)

## The Stripe data scrapper

First, we need to create the DB schema along with the Stripe tables. This is [the SQL script we used for that](https://gist.github.com/ka8725/1a1b95eebfb3d62be61d196290cf4f87).

Our product used Rails, so it had ActiveRecord and we could point to these tables our models. The are the ActiveRecord models we created for our convenience working with these tables in the Ruby script:

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

And this is the script we've come up with:

```ruby
next_page = nil

stripe_customers = {}

start = "1 Jan 2015".to_datetime.to_i

loop do
  params = {query: "created>#{start}", expand: ['data.subscriptions'], limit: 100}
  params[:page] = next_page if next_page

  customers = Stripe::Customer.search(params)
  next_page = customers.next_page
  puts "First: #{customers.first.id}"
  puts "Next page: #{next_page}"
  puts "Customers fetched: #{customers.count}"

  customers.each do |cus|
    stripe_customers[cus.email] ||= []
    customer_subscriptions = []
    cus.subscriptions.each { |sub|
      hash = {
        subscription_id: sub['id'],
        plan_id: sub['plan']['id'],
        status: sub['status']
      }
      customer_subscriptions << hash
    }

    stripe_hash = {
      customer_id: cus['id'],
      description: cus['description'],
      created_at: Time.at(cus['created'] || 0),
      metadata: cus['metadata'],
      subscriptions: customer_subscriptions,
      deleted: false
    }
    stripe_hash[:deleted] = true if cus["deleted"]
    stripe_customers[cus.email] << stripe_hash
  end
  break if customers.count < 100
end

stripe_customers.each do |key, value|
  value.each do |v|
    StripeCustomer.create(
      email: key,
      stripe_id: v[:customer_id],
      created_in_stripe: v[:created_at],
      description: v[:description],
      deleted: v[:deleted],
      metadata: v[:metadata]
    )

    v[:subscriptions].each do |sub|
      StripeSubscription.create(
        stripe_id: sub[:subscription_id],
        stripe_customer_id: v[:customer_id],
        plan_id: sub[:plan_id],
        status: sub[:status]
      )
    end
  end
end
```

This script fetches all Stripe customers along with their subscriptions. Later, using this data we can compare it agains our app DB and find any deviations.

We run this script on the server with the [rails runner](https://guides.rubyonrails.org/command_line.html#bin-rails-runner). Its run can take a while. Not to get the process killed with a closed SSH connection to the server, we use those [screen](https://www.gnu.org/software/screen/) utility. At least the first time, we have to run it like that manually. Just to verify all is good. Later, we can automate it so that it runs itself by schedule. We've collected 85k customers and 8,5k subscriptions. It took around 1h. Not bad for this range of data.

![Collected data from Stripe](/images/data-stripe.jpg)

## Analyze Stripe data discrepancies with SQL

We are all set. Since the data is there we can use SQL to find all deviations. We will use joins, filters, and aggregation functions for that.

