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

## Discrepancies in Stripe integrations

Stripe integrations often have data consistency issues, such as users being on different subscription plans in the app and Stripe. This can result in lost revenue or jeopardize customer success stories.

For example, a customer is premium within the app, while Stripe has no active subscription. This type of discrepancy can result in lost revenue for the business. Another potential error is when a customer overpays. In this case, the customer is on the free plan within the app while having an active subscription to the premium plan in Stripe. This can jeopardize the customer success story.

## Stripe integration state of our application

In this blog post, we will discuss the approach we took to resolve this kind of issues in our app. The app had around 80k users. Out of which 10% are on the premium plan. We know that some of them are overpaying while others are underpaying. This could be due to manual data manipulation in Stripe, missing webhooks, or bugs in our system.

While we used Ruby for scripting, this solution is universal and can be applied to applications written in other languages, such as Python, Node.js, Java, Rust, and Go.
