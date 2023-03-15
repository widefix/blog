---
layout: post
title: "How to generate rake task"
description: "Ruby on Rails guides for generate rake task. If you want to write new rake task you can use rails generate task generator. It is Ruby On Rails generator which generates scaffold for the rake task"
tags: [ruby, rails, rake]
share: true
featured_post: true
comments: true
redirect_from:
  - /2012/03/14/how-to-generate-rake-task/
---


Have you ever created your own __rake tasks__? If you frequently create them, this post will prove to be quite valuable. I won't delve into what a __rake task__ is since there is already an abundance of information available on the topic. However, I will provide you with a simple and efficient method for generating __rake tasks__.


<a onclick="_gaq.push(['_trackEvent', 'Reference', 'Packt', '#rake-task-management-essentials']);" href="https://www.packtpub.com/product/rake-task-management-essentials/9781783280773?_ga=2.19088061.400786981.1668522155-1689462152.1668522155" target="_blank" ref="nofollow">
  <img src="/images/rake_book.jpg" alt="Rake Task Management Essentials" align="right" vspace="5" hspace="5" width="120"/>
</a>

> I've authored a book on the subject of **Rake** called **Rake Task Management Essentials**. If you found the content of this post interesting and would like to learn more about this remarkable tool, I highly recommend purchasing a copy from [here](https://www.packtpub.com/product/rake-task-management-essentials/9781783280773?_ga=2.19088061.400786981.1668522155-1689462152.1668522155){:ref="nofollow" target="_blank"}. I assure you that after reading the book, you will have a thorough understanding of the primary objectives of **Rake** and how to utilize it effectively in your development process, daily tasks, or just for fun. You will also learn how to streamline and optimize your __Rake tasks__. The book covers all of Rake's features with easy-to-follow and practical examples.

While working on another __Rake task__, I stumbled upon an intriguing generator in __Ruby on Rails__. What's surprising is that despite reading numerous posts, documentation, books, tutorials, and watching screencasts, I had never encountered it before. Even more astonishing is that I have never heard anyone mention it on any podcasts. I searched for information on this particular generator on Google but found nothing. As a result, I decided to share my findings here.

If you're interested in creating your own Rake task, there are two approaches you can take (or so I believed prior to this):

1. Write it from the ground up.
2. Copy and paste code from an existing __Rake task__ and modify it as necessary.

As it turns out, there is a third approach to creating __Rake tasks__ - by simply utilizing this __Rake generator__:

```shell
$ rails g task my_namespace my_task1 my_task2
```

It generates a scaffold for the new __rake tasks__ located within the `lib/tasks/my_namespace.rake` file:

```ruby
namespace :my_namespace do
  desc "TODO"
  task :my_task1 => :environment do
  end

  desc "TODO"
  task :my_task2 => :environment do
  end
end
```

Now, when you have the starting point, write some code inside the __rake tasks__. This way you save time and start from what matters.

Let's make sure these __rake tasks__ are really there and can be run:

```shell
$ rake -T | grep my_namespace
```

That command outputs with the following content:

```shell
rake my_namespace:my_task1  # TODO
rake my_namespace:my_task2  # TODO
```

That print means there are two rake tasks defined `my_task1` and `my_task2` under `my_namespace`. They are ready to use. But they are useless until you write some code there. The TODO(s) signifies that you should describe these tasks.

### Conclusion

As you see, it's pretty easy to create your own __rake tasks__. The generator saves some time for you defining the skeleton. You do only what relates to the job - the rake tasks behavior. Thanks for reading and happy coding!

### Afterword

At [WideFix](https://widefix.com){:ref="nofollow" target="_blank"}, we take pride in our expertise and experience. You can trust that our solutions will not harm your business and will always keep your site running smoothly. You can rely on us to provide confident and effective solutions that meet your needs.

<div style="display: flex;align-items:center;justify-content: center;margin-top: 20px;">
  <a class="btn" style="background-color: #f04338; cursor: pointer;font-size: 24px;" target="_blank" rel="nofollow" href="https://calendly.com/andrei-kaleshka/30min">Schedule a call</a>
</div>
