---
layout: post
title: "Send Emails with SendGrid: A Step-by-Step Guide for Ruby on Rails Applications"
modified: 2023-03-15 15:29:47 +0100
description: "Learn how to easily send emails from your Ruby on Rails application using SendGrid. Our step-by-step guide will show you how to configure SendGrid and create a mailer class to send custom emails. Start sending personalized emails with ease!"
tags: [rails, mailer]
featured_post: false
keywords: "config sendgrid, use rails to send emails,"
image: sendgrid-rails.jpg
---

Sending emails from a Ruby on Rails application can be a critical aspect of many web applications. Whether it's for sending password resets, notifications, newsletters or transactional emails, you want your emails to be reliable and fast. That's where SendGrid comes in. This article guides you through the process of sending emails from your Ruby on Rails application using SendGrid.

Before you start, it's crucial to understand that username and password authentication for email delivery is no longer sufficient. Nowadays, email provider services like SendGrid require more rigorous verification processes to ensure secure and reliable email delivery. As such, the first step in this journey is setting up your SendGrid account properly.

### SendGrid Account Setup

To get started with [SendGrid](https://sendgrid.com/){:ref="nofollow" target="_blank"} in your Ruby on Rails application, you first need to sign up for a SendGrid account and [obtain an API key](https://docs.sendgrid.com/ui/account-and-settings/api-keys#creating-an-api-key){:ref="nofollow" target="_blank"}. Once you have created it, make sure to copy it somewhere. Otherwise, you won't be able to read it later.

It's recommended to have [completed the Domain Authentication process](https://docs.sendgrid.com/ui/account-and-settings/how-to-set-up-domain-authentication){:ref="nofollow" target="_blank"} to ensure the deliverability of your emails. This step requires registering your domain, either your own or one provided by other services such as Heroku that generate it automatically. By authenticating your domain, you can verify that you are a legitimate sender, improve email deliverability, and reduce the risk of your emails being flagged as spam.

When using SendGrid to send emails from your Ruby on Rails application, it's essential to [verify the email address from which the emails will be sent](https://docs.sendgrid.com/ui/sending-email/sender-verification){:ref="nofollow" target="_blank"}. This verification process involves adding the email address to your SendGrid account and proving that you have access to it. Failure to verify the email address can result in errors when attempting to send emails, such as authentication failures or email delivery issues. Therefore, it's crucial to verify any email addresses you plan to use for sending emails to ensure reliable and error-free email delivery.

After these steps completed, you should have:
1. The API key (a long abrakadabra string) like this: `SG.ve9OolaiLeenoh0iatoon0.hei8geiz1Shoorohtai6choopah8cahjae9vako8uBa`
1. Verified domain, let it by `mydomain.com`
1. Verified sender email address, let it be `hello@mydomain.com`

### Configure server

The Rails application will be configured via environment variables, which should be defined on your server (or on your local machine if you want to send emails from it):

```
SMTP_DEFAULT_FROM:        <your sender email>
SMTP_DOMAIN:              <your domain>
SMTP_PASSWORD:            <your api key>
SMTP_LOGIN:               apikey
SMTP_PORT:                587
SMTP_SERVER:              smtp.sendgrid.net
```

> Note that some of the values are static, while others are placeholders that you should replace with your own values. `SMTP_LOGIN`, `SMTP_PORT`, and `SMTP_SERVER` are static and will always have the same values. It is important to note that `SMTP_LOGIN` will always equal apikey, and you will not have your own value for that.

Here is an example of how to do that using the Heroku command line:

```bash
heroku config:set SMTP_DEFAULT_FROM="Hello <hello@mydomain.com>" SMTP_DOMAIN=mydomain.com SMTP_LOGIN=apikey SMTP_PASSWORD=SG.ve9OolaiLeenoh0iatoon0.hei8geiz1Shoorohtai6choopah8cahjae9vako8uBa SMTP_PORT=587
```

### Configure Ruby On Rails

Emails are typically sent from a production server. Therefore, you need to add the necessary configuration to the `config/environments/production.rb` file as follows:

```ruby
  config.action_mailer.smtp_settings = {
    port: ENV.fetch('SMTP_PORT'),
    address: ENV.fetch('SMTP_SERVER'),
    user_name: ENV.fetch('SMTP_LOGIN'),
    password: ENV.fetch('SMTP_PASSWORD'),
    domain: ENV.fetch('SMTP_DOMAIN'),
    authentication: :plain,
    enable_starttls_auto: true
  }
  config.action_mailer.delivery_method = :smtp
```

Make sure that these settings are not overridden elsewhere in this file.

If you need to send emails from development or staging mode, add these lines to the respective files `config/environments/development.rb` or `config/environments/staging.rb`. Deliver these changes to your server.

### Testing

That's all the steps needed to get it done. But before moving on to your next task, let's make sure everything is working correctly. Open the Rails console and define a variable with the email address you want to send a verification email to (for this example, we'll use `my@example.com`; replace it with your own):

```ruby
to_email = 'my@example.com'
```

And then paste there the following code snippet:

```ruby
mailer = ActionMailer::Base.new
mailer.mail(from: ENV['SMTP_DEFAULT_FROM'], to: to_email, subject: 'Test from WideFix guide', body: "Hello, you've got mail!").deliver
```

Wait a bit and you should receive the email in your inbox.

If you follow these steps correctly, all mailers defined in your Rails application will start using SendGrid for sending emails, and no additional configuration or checks are required.

### Afterword

At [WideFix](https://widefix.com){:ref="nofollow" target="_blank"}, we take pride in our expertise and experience. You can trust that our solutions will not harm your business and will always keep your site running smoothly. You can rely on us to provide confident and effective solutions that meet your needs.

<div style="display: flex;align-items:center;justify-content: center;margin-top: 20px;">
  <a class="btn" style="background-color: #f04338; cursor: pointer;font-size: 24px;" target="_blank" rel="nofollow" href="https://calendly.com/andrei-kaleshka/30min">Schedule a call</a>
</div>
