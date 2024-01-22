---
layout: post
title: "How to generate Rake task"
headline: "Easy way to create your own Rake task"
description: "Create your own rake task from scratch in a Rails app: rails g namespace task1 task2"
tags: [ruby, rails, rake]
share: true
featured_post: true
comments: true
image: rake-task.jpg
redirect_from:
  - /2012/03/14/how-to-generate-rake-task/
---

Some time ago I found a generator in __Ruby on Rails__'s sources to create a __Rake task__. There were no information about it anywhere. As a result, I decided to share my findings. This post will show you a simple and efficient method for generating them.

## Several ways to create Rake tasks

There are at least two known approaches you can take:

1. Write it from scratch.
2. Copy and paste existing code and modify it as necessary.

## The generator way to create Rake tasks

As it turns out, there is a third approach - utilize this __Rake generator__:

```shell
$ rails g task my_namespace my_task1 my_task2
```

It generates a scaffold for the new __Rake tasks__ located within the `lib/tasks/my_namespace.rake` file:

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

Now write some code inside the tasks' body. This way, you save time creating the preparation code and concentrate on what matters.

Confirm that they are real and can be executed:

```shell
$ rake -T | grep my_namespace
```

The command outputs the following content:

```shell
rake my_namespace:my_task1  # TODO
rake my_namespace:my_task2  # TODO
```

It indicates two Rake tasks (`my_task1` and `my_task2`) defined under the namespace `my_namespace`. However, they are empty and will do nothing until you add some code. The TODO comments remind you about that.

## It has never been easier

The generator provides a skeleton for you. It's easy to use and saves you time. You only need to focus on the task behavior.

## Learning more

<a href="https://www.packtpub.com/product/rake-task-management-essentials/9781783280773" target="_blank" ref="nofollow">
  <img src="/images/rake_book.jpg" alt="Rake Task Management Essentials" align="right" vspace="5" hspace="5" width="120"/>
</a>

I've authored a book on the subject called **Rake Task Management Essentials**. To learn more about this remarkable tool, I recommend purchasing a [copy](https://www.packtpub.com/product/rake-task-management-essentials/9781783280773){:ref="nofollow" target="_blank"}. After reading, you will understand how to use **Rake** effectively in your daily tasks. The book guides you through easy-to-follow and practical examples.
