---
layout: post
title: "Cheaper and Risk-Free Ruby on Rails App Redesign"
modified: 2023-08-30 15:06:43 +0200
description: "Learn how to apply new design to a Ruby on Rails app without risks to your business and do that cheaper.."
tags: [rails-development]
featured_post: false
toc: true
image: redesign-app.jpg
---

## Ruby on Rails app redesigning challenges

Redesigning a Ruby on Rails application is a well-known challenge for many projects. Any project UI gets outdated. It needs to get a fresh look that's more appealing to the users. It may not be an issue for web apps without live users. But it's a tricky task for already launched businesses serving thousands of users per day.

While a development team is redesigning, the application should continue functioning. At the development time, the new design gets validated and tested against the back-end. If the back-end is incompatible, it must be adapted to the new realm. These changes should not break the old functionality. Overcoming these issues is essential in a Ruby on Rails application redesign.

![Ruby On Rails redesign decision](/images/redesign-decision.jpg)

This article shares the approach we took to apply the new design in one of our projects. The changes we made increased the project revenue by 30%. As a bonus, the implemented changes unleashed many other opportunities, including:

- Building a modern mobile application.
- Making the code more fault-tolerant, performant, and stable.
- Adding new features, such as preventing account sharing, that can increase the app revenue.
- Making the tech stack upgrade easier.
- Implementing traffic control and advanced caching.
- Making SEO optimization easier.

## Why redesigning a Ruby on Rails app

There are several reasons why an app may consider implementing a new UI/UX design. Regardless of the motive, the ultimate goal is always the same - **to increase revenue**. Note, that keeping users using the app and not going away is the same goal.  Due to an old and unhandy design, an app can make the customers leave. In this case, redesign also can help. If it's clear that a redesign won't have a positive impact on revenue, it may be an unnecessary expense. Redesigning is usually an expensive change. So learn from the users if the design is a problem before making this decision.

![Ruby On Rails redesign weigh](/images/redesign-weigh.jpg)

## What is the new design

A new design consists of screens (mockups) created by a designer using software like Figma or Adobe Photoshop.

In our case, the client provided the mockups, and our task was to turn them into code and integrate them with the existing back-end. We aimed to minimize downtime during the transition and reduce development efforts.

![What is the new design](/images/redesign-new-design.jpg)

## Different technical approaches of a Ruby on Rails app redesign

Nowadays, web projects must be responsive and have a mobile application. Modern web app design features a rich UI with many elements on one page. The old-fashioned way of generating HTML on the back-end is going away. Instead, a separate web front-end or mobile app handles the front-end, while the back-end serves data via API.

In pure Ruby On Rails applications, the front-end code lives alongside the back-end. That can fulfill modern web app requirements and is cheap in the beginning. However, it becomes hard to maintain due to the mix of different technologies in one place. It makes it difficult to find developers who can understand and maintain the system. We prefer separate back-end and front-end. The specialists can do their job quickly with high quality on their end.

![Redesign Ruby On Rails business](/images/redesign-business.jpg)

## Risk-free approach of a Ruby on Rails app redesign

The project we received was a Ruby On Rails application with a Rest API implemented on Grape. An iOS app used this API. The web version used ERB and Slim templates with a UI from the previous decade. Some dynamic features on the web used Knockout.js, which is no longer maintained.

To update the UI, we used the Next.js framework with TypeScript and implemented GraphQL for the API. To avoid errors, we created a separate repository for the new UI and extracted functionality that could be reused in both the old app and the new UI.

The project took almost a year with 2 developers and 1 project manager working on it. To deploy the changes, we used CloudFront as a proxy on top of the old app and the new front-end app. We gradually switched web requests to the new UI using a feature flag to reduce the risk of failures or outages. The transition went smoothly without major issues.

![Risk free Rails App Redesign](/images/rails-app-redesign.png)

As a bonus, we got all requests geolocated since they pass through the AWS CloudFront. That allowed us to control the users' network traffic and fight against sharing accounts.

## Our results of the Ruby on Rails app redesign

Switching to the new design made the project more attractive to users, resulting in more signups and increased satisfaction among old users. This allowed us to increase charges by 20% and revenue by 30%. The redesign expenses were paid off within the first 3 months after release. See below for the paid user dynamics analysis.

![User signups dynamics](/images/users-increase.png)

The release date was on the 1st of February 2021.

## Why our approach of Ruby on Rails app redesign is cheaper and less risky

Redesigning apps can be painful and distracting. The Rails assets pipeline changes often, making sticking with it turn the code into legacy quickly. Finding specialists to maintain this code without sacrificing quality on both front-end and back-end is challenging. Separating the front-end and leaving only the Rails back-end for the API makes redesigning and maintenance smoother, allowing for a diversified team with good specialists on both ends.

Next.js was a wise choice for the front-end, improving SEO with image optimization and cache facilities out of the box.

![Redesign Rails App SEO impact](/images/redesign-seo.png)

## Acknowledges

I'm grateful and proud to have worked with the following people on this project at different times:

- Daniel Dauwe
- Vadzim Jakushau
- Illia Pruskyi
- Soltan Yangibayev
- Svetlana Zhuravitskaya
- Alexey Mikitsik

<small class="side-note">
When seeking proficient expertise in Ruby on Rails development, explore the option of using a reputable talent marketplace. Toptal provides access to dependable [Ruby on Rails developers](https://www.toptal.com/ruby-on-rails) for hire, assisting companies with their critical web application requirements.
</small>
