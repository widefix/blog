---
layout: post
title: "Cheaper and Risk-Free Ruby on Rails App Redesign"
modified: 2023-05-13 15:06:43 +0200
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

This article will share the approach of applying the new design we took in one project. The changes we made increased the project revenue by 30%. As a bonus, the implemented changes unleashed many other opportunities. They include:
- Building a modern mobile application.
- Having the code more fault-tolerant, performant, and stable.
- New features, such as preventing account sharing, that can increase the app revenue.
- Easier the tech stack upgrade.
- Traffic control and advanced caching.
- Easier SEO optimization.

## Why redesigning a Ruby on Rails app

There are several reasons why an app may consider implementing a new UI/UX design. Regardless of the motive, the ultimate goal is always the same - **to increase revenue**. Note, that keeping users using the app and not going away is the same goal.  Due to an old and unhandy design, an app can make the customers leave. In this case, redesign also can help. If it's clear that a redesign won't have a positive impact on revenue, it may be an unnecessary expense. Redesigning is usually an expensive change. So learn from the users if the design is a problem before making this decision.

![Ruby On Rails redesign weigh](/images/redesign-weigh.jpg)

## What is the new design

A new design is a set of screens (mockups) prepared by a specialist (designer) using some special software, like Figma, Adobe Photoshop, etc.

In our case, the client already had the mockups of the new design. Our task was to turn it into the code and connect it with the existing back-end. We had to eliminate downtimes during the transition to the new design reducing the development efforts.

![What is the new design](/images/redesign-new-design.jpg)

## Different technical approaches of a Ruby on Rails app redesign

Nowadays, it’s hard to imagine a web project that isn’t responsive. The app should look good in all browsers, including mobile ones. Any project should have a mobile application. As a rule of thumb, modern web app design has a rich UI. It has many elements located on one page, usually not connected to each other in any way.

The old-fashioned way when the back-end generates HTML is going away. Nowadays a separate web front-end/mobile app handles the front-end. The back-end handles serving the data via API.

In pure Ruby On Rails applications, the front-end code lives alongside the back-end. This implementation can also fulfill all modern web app requirements. It’s also cheap, at least in the beginning. But it becomes hard with its maintenance later. It’s because of the tech overhead and mix of different technologies, Ruby/SQL/JavaScript/HTML/CSS, within one place. It becomes too hard to find a developer who can understand and further maintain this kind of system. And even if you find one, they might be too expensive. Have you ever bumped into an article about the full-stack developer myth? Google and you see how the issue is pervasive.

We prefer separate back-end and front-end, where the different specialists are at their places. They do the job well on their ends. They do that fast with high quality. They are replaceable. Hence, there is no bottleneck in some very specific specialist demands.

![Redesign Ruby On Rails business](/images/redesign-business.jpg)

## Risk-free approach of a Ruby on Rails app redesign

The initial state of the project when we got it was looking like that:
- It’s a usual Ruby On Rails application.
- With Rest API implemented on Grape. An iOS mobile app uses this API.
- Web website version uses ERB and Slim templates. The back-end generates them. UI is from the previous decade.
- Some dynamic features on the Web use Knockout.js (a JS framework that’s not maintained anymore).

Our plan was the following. For the new UI, we took Next.js framework with TypeScript and implemented GraphQL for API. To avoid possible errors on the main app, we created a separate repository for the new UI. If the GraphQL API needs some functionality that's used by the old app we carefully extract it so that the functionality can be reused in both places the old app and the new UI.

All this story took almost 1 year. At the same time, 2 devs and 1 project manager were working on it.

When it came to deploying the changes, we put CloudFront (AWS service) as a proxy on top of the old app. Then we gradually switched the web requests dispatching from the old app to the new one using a feature flag. This way we reduced the risks of having unpredictable failures or pitfalls, like server outages.  The transition went well and there were no major issues.

![Risk free Rails App Redesign](/images/rails-app-redesign.png)

As a bonus, we got all requests geolocated since they pass through the AWS CloudFront. That allowed us to control the users' network traffic and fight against sharing accounts.

## Our results of the Ruby on Rails app redesign

After the switching to the new design the project became more attractive to users and there were more signups started. The old users were better satisfied with the app. That allowed us to earn their credit and increase the charge by 20%. In summary, the revenue increased by 30%.

The redesign expenses were paid off within the first 3 months after the release.

Below are the results of the paid users dynamics analysis for the whole story of the project:

![User signups dynamics](/images/users-increase.png)

The release date was on the 1st of February 2021.

## Why our approach of Ruby on Rails app redesign is cheaper and less risky

I have many apps redesigned. Usually, that was a very painful process that seemed to last forever and didn't go without users' distraction. The main pain point is the Rails assets pipeline that's changing often in a new Rails version. Sticking with the Rails assets pipeline the code turns into legacy very fast. That in turn later makes maintenance and redesigning the app too hard.

But having the front-end separate and leaving for Rails back-end only API makes the redesigning and later maintenance process very smooth.

A discussion about the front-end could be a separate topic. But I want to mention that Next.js was a very wise choice. It allowed to improve SEO with their image optimization and cache facilities out of the box. So the SEO impact was very good as well.

![Redesign Rails App SEO impact](/images/redesign-seo.png)

## Acknowledges

I've been working on this project with several people in different periods of time. I'm very grateful to them and proud to work with such people alongside:

- Daniel Dauwe
- Vadzim Jakushau
- Illia Pruskyi
- Soltan Yangibayev
- Svetlana Zhuravitskaya
- Alexey Mikitsik
