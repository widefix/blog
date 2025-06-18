---
layout: post
title: "Fake signups: a threat to your business"
modified: 2023-01-04 15:00:00 +0000
description: "Learn why a sudden increase in new customers can pose a risk to your business and discover how to protect against fake signups. Find out how we successfully mitigated the impact of a signups spike in our Ruby on Rails application and kept our business running smoothly."
tags: []
comments: true
share: true
image: tsunami.jpg
---

**TL;DR:** Use captcha and email verification services.

Recently, we experienced a spike in the number of signed up customers within a **Ruby on Rails application** that we provide maintenance services for. As shown in the following graph, the spike occurred without any aggressive marketing campaigns:

![Signups spike in Stripe](/images/stripe_spike.jpg)

While an increase in new customers is generally a good thing, this particular spike turned out to be a false positive. It was likely the result of an attack, as almost all of the new signups used fake emails and the credit cards used for the signups were passed by Stripe without a CVC check.

To resolve this issue, we implemented a few solutions:

- Email verification: We added an email verification step to the signup process using the Mandrill API. This was an easy solution as the project was already using Mandrill to send emails.
- reCaptcha: We added a reCaptcha to the signup form to help prevent fake signups.
- Data cleanup: We removed the fake accounts from Drip, Stripe, and our database to clean up the data.

As a result, the number of new signups returned to a normal level, as shown in the following graph:

![Normal signups in Stripe](/images/normal_signups.jpg)

Overall, implementing email verification and reCaptcha helped to stabilize the number of new signups and protect the business and customer data. It's important to take necessary precautions to prevent fake signups and other potential attacks on your application. In this case, quick action helped to mitigate the impact of the fake signups and keep the business running smoothly.

If you have a **Ruby on Rails application** that needs maintenance, you're in the right place. At [WideFix](https://clutch.co/profile/widefix), we specialize in providing comprehensive maintenance services for Ruby on Rails applications. Our team of experienced developers is well-versed in all aspects of Ruby on Rails, so you can trust us to keep your application running smoothly.

Whether you need help fixing bugs, adding new features, or simply keeping your application up-to-date with the latest security patches, we've got you covered. Our maintenance services include:

- **Bug fixing**: If you've encountered any errors or issues with your application, we can quickly identify and fix the problem to ensure that your application is running smoothly.

- **Feature additions**: If you want to add new functionality to your application, we can help you plan and implement the changes you need.

- **Security updates**: Keeping your application secure is important, and we can help you ensure that your application is up-to-date with the latest security patches and best practices.

- **Performance optimization**: If your application is running slowly or experiencing other performance issues, we can help you identify and resolve the problem to improve the speed and reliability of your application.

In addition to these services, we also offer ongoing maintenance plans to ensure that your application stays in top shape. With our maintenance plan, you'll receive regular updates and support to keep your application running smoothly.
