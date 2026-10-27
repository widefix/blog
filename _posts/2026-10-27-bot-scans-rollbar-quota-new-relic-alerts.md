---
layout: post
title: "How bot scans used up my Rollbar quota and triggered New Relic alerts"
headline: "How bot scans used up my Rollbar quota and triggered New Relic alerts"
modified: 2026-10-27 12:00:00 +0100
description: "Automated scans for exposed secrets filled my Rails error feed. Here is how I filtered routing errors in Rollbar, and why monitoring noise matters."
tags: [rails, rails-development, monitoring, security]
featured_post: false
toc: true
image:
---

My Rails application started reporting exceptions for URLs that had nothing to do with its features:

```text
/private-key
/.env.live
/.env.stage
/static/.env
/panel/.env
```

Rollbar was using up my monitoring quota, and I also received New Relic alerts about deviations in request processing time.

The application was rejecting these requests. But rejecting unwanted traffic still had a cost.

## What were these requests?

<!-- Add the original Rollbar screenshot here before publication.
Suggested alt text: Rollbar events showing a burst of GET requests for private-key and environment files.
Caption: Multiple requests for secret-related paths arrived within the same second and generated routing errors.
-->

These looked like automated scans searching for exposed secrets. Environment files often contain database credentials, API tokens, and other sensitive configuration. Scanners try common paths across public websites, hoping to find a deployment that accidentally serves them.

The requests carried several different crawler names. Those names do not establish who sent them: a client can put any name in its `User-Agent` header.

The more useful evidence was the pattern: requests for secret-related filenames across many directories, arriving in rapid succession.

Rails reported that no routes matched. These exceptions were not evidence that the scanner had retrieved any secrets.

## How ordinary 404s filled Rollbar

When a request does not match a Rails route, Rails raises:

```ruby
ActionController::RoutingError
```

In production, exception handling turns that into a 404 response. But Rollbar was also capturing the exception.

Each attempt to fetch a nonexistent secret file could therefore consume another monitoring event.

That made unsolicited traffic compete with real application failures for my Rollbar quota. It also made the error feed harder to read: a customer-facing bug could end up buried among requests for files that never existed.

An exception inside a framework is not always an application failure that needs someone's attention. A customer being unable to complete an action deserves investigation. A scanner asking for `/private-key` usually does not deserve a separate error report.

## What New Relic showed

<!-- Add the original New Relic screenshot here before publication.
Suggested alt text: New Relic web transaction time chart with a temporary response-time spike to roughly 160 milliseconds.
Caption: Response time rose temporarily, with most of the increase in Web external and a smaller middleware contribution, before returning close to baseline.
-->

New Relic's web transaction chart showed a temporary rise in response time, reaching roughly 160 ms before returning close to its earlier baseline. Most of the increase appeared in the **Web external** category, with middleware also contributing.

I also received alerts about deviations in request processing time.

The chart shows a performance change, but it does not identify its cause. It covers a different time window from the Rollbar events, so these two screenshots alone do not establish a connection between that particular scan burst and the slowdown.

One possibility worth investigating is the work involved in reporting exceptions to an external service. Confirming that would require examining transaction traces and external calls during the spike. The aggregate chart does not identify Rollbar as the source of the external time.

The practical problem was already clear: unwanted requests were consuming error-reporting capacity, while performance alerts created additional investigation work.

## The fix: filter routing errors in Rollbar

I added an exception filter to the existing Rollbar initializer:

```ruby
# config/initializers/rollbar.rb

Rollbar.configure do |config|
  # Existing configuration...

  config.exception_level_filters.merge!(
    'ActionController::RoutingError' => 'ignore'
  )
end
```

This uses [Rollbar's documented exception filtering](https://docs.rollbar.com/docs/ruby). Using `merge!` preserves the other configured exception filters.

Once deployed, unknown URLs still receive a 404 response. Other application exceptions continue to reach Rollbar. Uncaught routing errors stop consuming Rollbar events.

There is a tradeoff: this also hides routing errors caused by legitimate broken links. Access logs and 404 metrics remain useful for finding those. If routing errors are especially valuable in your application, a narrower filter for known scan paths may be a better choice.

The documented filtering applies to uncaught exceptions. Explicit calls such as `Rollbar.error(exception)` need the `use_exception_level_filters: true` option if you want them to respect these filters too.

## Filtering reports does not block scanners

This change addresses Rollbar noise. It does not block the requests or eliminate the work Rails does to handle them.

If scan traffic becomes expensive enough to affect customers, rate limiting or filtering requests before they reach Rails is a separate step. Performance alerts also need their own investigation. Suppressing an exception report does not prove that a response-time issue is resolved.

For my immediate problem, filtering routing errors was a small change with a clear purpose: preserve error-reporting capacity for failures worth investigating.

## Monitoring capacity is part of reliability

For a team, filtering expected routing errors preserves the error-reporting budget for actionable failures and reduces time spent triaging scanner traffic. A cleaner error feed also makes customer-facing bugs easier to spot and prioritize. The benefit is shared: developers spend less time investigating irrelevant events, and the team gets more useful coverage from its monitoring subscription.

A public application receives traffic its developers never intended. Some of it will ask for nonexistent files, probe common vulnerabilities, or try random routes.

Returning a 404 handles the HTTP request correctly. It does not automatically make the request free.

In my case, the cost included Rollbar quota and time spent investigating New Relic alerts. Keeping expected internet noise out of the error feed helps preserve both monitoring capacity and attention for problems that affect users.
