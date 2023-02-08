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

While there are third-party gems that offer the ability to fake `Time.now` functionality, Rails has this built-in functionality as part of the `ActiveSupport::Testing::TimeHelpers` module. However, this module is only intended for use in testing and not in production environments.

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

> Tip: Use `Time.current` instead of `Time.now`. This blog post uses `Time.now` only for demonstration purposes due to its widespread usage over `Time.current`.

Here's an example of how I recently implemented this in a production environment. In our project, we have a function called `Plan#stripe_id` that links to a product pricing object. The pricing is dependent on the current time because on February 15th, the project's prices will be increased. Before February 15th, the system uses the old prices, but after that date, it uses the new prices.

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

### Be aware of the following security concerns before proceeding with these steps

Loading code from an external source via an HTTP link can pose a security risk as it may contain malicious code. A recommended solution is to use unit tests. However, unit tests cannot guarantee the behavior of code in a production environment. In emergency situations where time is of the essence, a faster and more creative approach may be necessary to ensure the code's integrity.

The security concern can be addressed by creating the link yourself. To do so, visit the GitHub Rails repository, search for the `time_helpers.rb` file, and click the "Raw" button. This will generate the link. However, it is important to note that even this manual process does not guarantee the absence of malicious code, as the resource may have been tampered with by hackers. Always review the contents before evaluating them:

```ruby
url = "<HTTP LINK>"
code = open(url).read
puts code
```

It's important to carefully review the code before evaluating it, to ensure it is the original, intended code and not something malicious. Only after confirming the authenticity of the code should you include it as a module:

```ruby
eval(code)
include ActiveSupport::Testing::TimeHelpers
```

If there is limited time to review the code, a simple check can help prevent dangerous actions. This can be done by raising an error if a specific line of code is not present. This will serve as a safeguard and ensure that any malicious code is not executed:

```ruby
raise 'dangerous code' unless code.include?('module ActiveSupport')
```

Manipulating production systems can be risky and should only be done with a high level of confidence in what you are doing. Although in some scenarios, the console is the only solution to fix a production issue, it should be approached with caution. Before making any changes, consider the potential impact and weigh the decision carefully, as even a small mistake can have significant consequences. In some cases, the cost of fixing the issue through other means may be less than the cost of fixing the mistake made in the production console.

At [WideFix](https://widefix.com){:ref="nofollow" target="_blank"}, we take pride in our expertise and experience. You can trust that our solutions will not harm your business and will always keep your site running smoothly. You can rely on us to provide confident and effective solutions that meet your needs.

<div style="display: flex;align-items:center;justify-content: center;margin-top: 20px;">
  <a class="btn" style="background-color: #f04338; cursor: pointer;font-size: 24px;" target="_blank" rel="nofollow" href="https://widefix.com">Hire Ruby On Rails expert now</a>
</div>
