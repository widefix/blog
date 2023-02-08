---
layout: post
title: "Fake Time.now in production"
modified: 2023-02-08 13:59:03 +0100
description: "Learn how to mimic the current time in production on a Rails server and debug your application. Discover techniques to set the time and date in production, as well as tips on how to simulate travel time. Get the most out of your Rails application in production with these helpful tips."
tags: [rails, debug]
featured_post: false
keywords: "simulation of production time,rails console time manipulation,production environment time adjustment,debugging in live production,time travel in rails,changing date and time in production,production debugging in rails,simulate server time in production,rails application production debugging"
image: fake-time-now.png
---

TL;DR: see this [gist](https://gist.github.com/ka8725/95c21119b8fd4883925132ac0514f966){:ref="nofollow" target="_blank"}.

As a Ruby on Rails expert, you may find yourself wondering how to debug a Rails application in production. In some cases, you may need to mimic the current time to check a time-dependent function result.

While there are third-party gems that offer the ability to fake the Time.now functionality, Rails has this built-in functionality as part of the `ActiveSupport::Testing::TimeHelpers` module. However, this module is only intended for use in testing and not in production environments.

```ruby
Time.now          # => Wed, 08 Feb 2023 14:01:33 UTC +00:00
travel 1.day.ago
Time.now          # => Tue, 07 Feb 2023 14:01:33 UTC +00:00
Date.current      # => Tue, 07 Feb 2023
```

Check in production console:

```ruby
travel 1.day.ago
# => Traceback (most recent call last):
#    NoMethodError (undefined method `travel' for main:Object)
```

If you want to use the `travel` or `freeze_time` method in production, you can load the module source code and include it into the console runtime:

```ruby
mod = "https://raw.githubusercontent.com/rails/rails/2a2a6ab6219b12e9e77931a60fe83c658db44ac7/activesupport/lib/active_support/testing/time_helpers.rb"
eval(open(mod).read)
include ActiveSupport::Testing::TimeHelpers

travel_to(1.day.ago) { Time.now } # => Tue, 07 Feb 2023 14:01:33 UTC +00:00
```

> Tip: Use `Time.current` instead of `Time.now`. This blog post uses `Time.now` only for demonstration purposes due to its widespread usage over Time.current.

Here's an example of how I recently implemented this in a production environment. In our project, we have a function called Plan#stripe_id that links to a product pricing object. The pricing is dependent on the current time because on February 15th, the project's prices will be increased. Before February 15th, the system uses the old prices, but after that date, it uses the new prices.

Here's how the method is defined:

```ruby
class Plan < ApplicationRecord
  NEW_PRICES_TIME = '15 Feb 21:00 UTC'.to_datetime

  def stripe_id
    if NEW_PRICES_TIME.past?
      stripe_price_id || name
    else
      name
    end
  end
end
```

Please note that name is a deprecated column referring to an outdated Stripe product price.

Once this feature is deployed to production, we will verify its functionality across all plans by accessing the production Rails console and reviewing the pre-implementation values.

Checking how it works now:

```ruby
Plan.all.map(&:name) # => ["a", "b"]
```

And then we do the same at the traveled time after Feb 15:

```ruby
mod = "https://raw.githubusercontent.com/rails/rails/2a2a6ab6219b12e9e77931a60fe83c658db44ac7/activesupport/lib/active_support/testing/time_helpers.rb"
eval(open(mod).read)
include ActiveSupport::Testing::TimeHelpers

travel_to("16 Feb, 2024".to_datetime) { Plan.all.map(&:name) } # => ["a_2023", "b_2023"]
```

With this verification process, we can now confidently say that the production environment is functioning correctly and will be utilizing the correct prices after Feb 15, thereby avoiding any unexpected issues in the final stages.

Note, doing that might be dangerous and can break your data if you call some methods that write data or call third-party APIs. This method implies that you know what you are doing and you are familiar with the code you test like that in production console.
