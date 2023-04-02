---
layout: post
title: "Make your Ruby on Rails app 80x faster with SQL"
modified: 2023-03-30 11:59:17 +0200
description: "Maximize Ruby on Rails expertise. Take your applications to the next level with SQL. Learn about the importance of SQL for Rails experts. Discover how it can enhance performance and efficiency."
tags: [sql, active_record, rails]
featured_post: false
toc: true
image: why-learn-sql.jpg
---

SQL can improve the performance and efficiency of your Ruby on Rails application. No need for heavy technologies. No need for switching to another programming language or framework.

SQL is a powerful tool that can take your Ruby on Rails expertise to the next level. Nowadays many technologies claim to replace SQL or deem Ruby on Rails as "too slow". But it remains a popular and efficient choice for many web projects. This article will explore the importance of SQL for Ruby on Rails experts. It will show why it's a must-have skill in today's development landscape.

## Why Ruby on Rails can be slow

Imagine the following class that’s used in a Rails controller to feed data to a page in your application. This class may look familiar to you. I’ve encountered similar classes in real-world applications:

```ruby
class ServicesStatsQuery
  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def call
    projects_full = []
    projects_empty = []
    Service.where(user: user, status: "approved", active: true)
      .order(category_id: :asc).each do |service|
      ratings_average = 0
      ratings_count = 0
      ratings_total = 0
      Rating.where(reviewee: user).each do |rating|
        project = Project.find(rating.project_id)
        if project.category_id == service.category_id
          ratings_count += 1
          ratings_total += rating.rating
        end
      end
      ratings_average = (ratings_total / ratings_count.to_f).round(1).to_s if ratings_count != 0 && ratings_total != 0
      completed_projects_count =
        Project.where(vendor: user, status: "Complete", category_id: service.category_id).size
      service_hash = {
        category_id: service.category_id,
        category_name: Category.find(Category.find(service.category_id).parent_id).name,
        subcategory_name: Category.find(service.category_id).name,
        completed_projects_count: completed_projects_count,
        ratings_count: ratings_count,
        ratings_average: ratings_average,
      }
      resolved_hash = service_hash.transform_keys{ |k| k.to_s.camelize(:lower) }
      if completed_projects_count > 0
        projects_full.push(resolved_hash)
      else
        projects_empty.push(resolved_hash)
      end
    end
    projects_full.sort_by!{ |k| -k["completedProjectsCount"] }
    projects_full.push(*projects_empty)

    projects_full
  end
end
```

Your application is running in production and serving the needs of hundreds of users. You've noticed that the related page is becoming slower and slower with each passing day. This can be a frustrating problem to solve. It's natural to feel tempted to consider drastic measures. You can think of switching to a faster programming language. Or you might plan to use heavy technology.

Before taking such drastic steps take a step back and understand the root cause of the issue.

There are a few things that could be contributing to the slowness of this code:

- N+1 queries: The code is making a separate database query for each rating. Then it gets the associated project. That can become slow if there are a large number of ratings.

- Nested `each` loops: The code is using this method to iterate over the Service. For each service in the nested loop, it iterates through all related Rating records. That can also be slow if there are many records. Instead, it would be better to use SQL joins to fetch all the data in a single query.

- Redundant queries: The code is calling `Category.find` many times. Instead, better to fetch all the category data using a single query. And then use it to populate the `service_hash` object.

Optimizing this code will need a combination of SQL query optimization. That should cut unnecessary database queries and improve the performance of the code.


## How to analyze slow Ruby On Rails code

There are plenty of tools out there, like [bullet](https://github.com/flyerhzm/bullet){:ref="nofollow" target="_blank"}, [benchmark-ips](https://github.com/evanphx/benchmark-ips){:ref="nofollow" target="_blank"}, or any others.

But before taking these radical steps use what you already have.  Open logs  (use command `tail -f log/development.log` for local).  Observe what happens there while you open the slow page in your browser. If you spot many repeating lines like this one you have an N+1 problem:

```ruby
00:03:22 web.1 | Rating Load (1.6ms)  SELECT "ratings".* FROM "ratings" WHERE "ratings"."user_id" = $1  [["user_id", 15]]
```

Pay attention to the phrase "Rating Load" as it serves as an indicator. If you notice "CACHE Rating Load", there's no need to worry. The object is already in memory, retrieved from there without accessing the database. This suggests that eager loading is already working.

Another tool is to visually inspect the code. You can feel discomfort and uncertainty when trying to understand how the code pieces relate to each other. Yet, this is not related to performance. The most crucial aspect is that the code contains a nested loop, which indicates that its complexity is squared. As more objects are iterated, a squared function grows rapidly:

![Growth rate for different functions](/images/plot.png)

Sorry for getting into the math, but it's important to understand that your code should ideally grow linearly or at least logarithmically. This is the best way to ensure that your code's performance remains optimal for many years to come.

If you are unsure about what all of that means, now is a good time to start learning about the theory of algorithms and data structures.

## Use SQL to improve Rails application performance

To fetch all the required data in a single query while performing the necessary aggregation, sorting, and grouping, consider using this SQL query:

```sql
select
  s.category_id as "categoryId",
  pc.name as "categoryName",
  c.name as "subcategoryName",
  count(p.id) as "completedProjectsCount",
  r.count as "ratingsCount",
  r.avg as "ratingsAverage"
  from services s
  join categories c on c.id = s.category_id
  join categories pc on pc.id = c.parent_id
  left join lateral (
    select count(r.id), cast(round(coalesce(avg(r.rating), 0), 1) as text) as avg from ratings r
    join projects rp on rp.id = r.project_id and s.category_id = rp.category_id
    where r.reviewee_id = :user_id
  ) r on true
  left join projects p on p.vendor_id = :user_id and p.status = 'Complete' and p.category_id = s.category_id
  where s.status = 'approved' and s.active and s.user_id = :user_id
  group by s.category_id, pc.name, c.name, r.count, r.avg
  order by count(p.id) desc, s.category_id asc
```

One way to test this query is to replace the placeholder `:user_id` with an actual user id. Then, we can open the DB console and paste the query to see if it produces the expected results.

Make sure the query is successful and returns the desired results. Then we can replace the slow Ruby code with this efficient SQL query:

```ruby
class ServicesStatsQuery
  SQL = <<~SQL
    select
      s.category_id as "categoryId",
      pc.name as "categoryName",
      c.name as "subcategoryName",
      count(p.id) as "completedProjectsCount",
      r.count as "ratingsCount",
      r.avg as "ratingsAverage"
      from services s
      join categories c on c.id = s.category_id
      join categories pc on pc.id = c.parent_id
      left join lateral (
        select count(r.id), cast(round(coalesce(avg(r.rating), 0), 1) as text) as avg from ratings r
        join projects rp on rp.id = r.project_id and s.category_id = rp.category_id
        where r.reviewee_id = :user_id
      ) r on true
      left join projects p on p.vendor_id = :user_id and p.status = 'Complete' and p.category_id = s.category_id
      where s.status = 'approved' and s.active and s.user_id = :user_id
      group by s.category_id, pc.name, c.name, r.count, r.avg
      order by count(p.id) desc, s.category_id asc
  SQL

  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def call
    sql = ActiveRecord::Base.sanitize_sql_array([SQL, user_id: user.id])
    ActiveRecord::Base.connection.execute(sql).to_a
  end
end
```

This SQL query can provide fast results for most Ruby On Rails applications. Although, it assumes that the DB has appropriate indexes defined.

## Native SQL is much faster than the pure Ruby on Rails code

It's time to perform measurements. First, install the [benchmark-ips](https://github.com/evanphx/benchmark-ips){:ref="nofollow" target="_blank"} gem. Then you can prepare the following code and save it in a file. For example, `t.rb`, in the root directory of your Rails application:

```ruby
require 'benchmark/ips'

user = User.find(10)
service = ServicesStatsQuery.new(user)

Benchmark.ips do |x|
  x.report("ruby") { service.call_ruby }
  x.report("sql") { service.call_sql }
  x.compare!
end
```

We change the `ServicesStatsQuery` a bit to have the two methods defined `call_ruby` and `call_sql` instead of one method `call`:

```ruby
class ServicesStatsQuery
  SQL = <<~SQL
    select
      s.category_id as "categoryId",
      pc.name as "categoryName",
      c.name as "subcategoryName",
      count(p.id) as "completedProjectsCount",
      r.count as "ratingsCount",
      r.avg as "ratingsAverage"
      from services s
      join categories c on c.id = s.category_id
      join categories pc on pc.id = c.parent_id
      left join lateral (
        select count(r.id), cast(round(coalesce(avg(r.rating), 0), 1) as text) as avg from ratings r
        join projects rp on rp.id = r.project_id and s.category_id = rp.category_id
        where r.reviewee_id = :user_id
      ) r on true
      left join projects p on p.vendor_id = :user_id and p.status = 'Complete' and p.category_id = s.category_id
      where s.status = 'approved' and s.active and s.user_id = :user_id
      group by s.category_id, pc.name, c.name, r.count, r.avg
      order by count(p.id) desc, s.category_id asc
  SQL

  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def call_ruby
    projects_full = []
    projects_empty = []
    Service.where(user: user, status: "approved", active: true).order(category_id: :asc).each do |service|
      ratings_average = 0
      ratings_count = 0
      ratings_total = 0
      Rating.where(reviewee: user).each do |rating|
        project = Project.find(rating.project_id)
        if project.category_id == service.category_id
          ratings_count += 1
          ratings_total += rating.rating
        end
      end
      ratings_average = (ratings_total / ratings_count.to_f).round(1).to_s if ratings_count != 0 && ratings_total != 0
      completed_projects_count = Project.where(vendor: user, status: "Complete", category_id: service.category_id).size
      service_hash = {
        category_id: service.category_id,
        category_name: Category.find(Category.find(service.category_id).parent_id).name,
        subcategory_name: Category.find(service.category_id).name,
        completed_projects_count: completed_projects_count,
        ratings_count: ratings_count,
        ratings_average: ratings_average,
      }
      resolved_hash = service_hash.transform_keys{ |k| k.to_s.camelize(:lower) }
      if completed_projects_count > 0
        projects_full.push(resolved_hash)
      else
        projects_empty.push(resolved_hash)
      end
    end
    projects_full.sort_by!{ |k| -k["completedProjectsCount"] }
    projects_full.push(*projects_empty)

    projects_full
  end

  def call_sql
    sql = ActiveRecord::Base.sanitize_sql_array([SQL, user_id: user.id])
    ActiveRecord::Base.connection.execute(sql).to_a
  end
end
```

Run it with the command: `rails runner t.rb` and see the results:

```ruby
Warming up --------------------------------------
                ruby     1.000  i/100ms
                 sql    48.000  i/100ms
Calculating -------------------------------------
                ruby      5.658  (± 0.0%) i/s -     29.000  in   5.147460s
                 sql    451.144  (± 8.6%) i/s -      2.256k in   5.042193s

Comparison:
                 sql:      451.1 i/s
                ruby:        5.7 i/s - 79.74x  slower
```

Performance boost of almost 80 times! The slow-loading page that took over 30 seconds now loads within 300ms. This significant improvement is not the programming language or framework merit.

## Demo: Faster SQL in Ruby on Rails App

I have developed a pdemo application using both Ruby and SQL versions](https://blog.widefix.com/importance-sql-for-rails-experts/){:ref="nofollow" target="_blank"} and made it available on GitHub as an open source project. This means that you have the opportunity to experiment with the code and run benchmarks on your own.

## Determine whether to use the measurement tools or not

You can analyze performance issues and measure optimization results without fancy tools. [benchmark-ips](https://github.com/evanphx/benchmark-ips){:ref="nofollow" target="_blank"} is for demonstration purposes. The best tools are reading the code, and understanding it. Then analyze its complexity. Finally, use SQL knowledge. These tools are enough. Nothing can replace them. Well, except in the distant future, ChatGPT may offer more help.

There are always plenty of built-in tools by your hand. Learn how to use them. For example, moving further, the written SQL can be slow. You will have to check why. Use [explain analyze](https://www.postgresql.org/docs/current/sql-explain.html){:ref="nofollow" target="_blank"} for that. This is a built-in tool in all modern SQL databases.

## Why Ruby on Rails expert should know SQL

Ruby on Rails is a powerful web application framework. It provides developers with high-level abstractions and conventions. That allows to build web applications quickly and efficiently. But, despite its powerful abstractions, Ruby on Rails experts need to know SQL.

SQL allows Ruby on Rails experts to write efficient and optimized database queries. That can improve the performance of a web application. By understanding SQL, a Ruby on Rails expert can design the database schema and data access layer.  If that's done well, the application maximizes performance, scalability, and maintainability.

SQL is a widely-used and powerful language. People use it beyond interacting with the database. Ruby on Rails experts use SQL to perform complex calculations and data transformations. They can generate reports that are challenging to achieve using Ruby code alone.

SQL allows Ruby on Rails experts to have more control over their web applications. They write more efficient and optimized code. They make better data-driven decisions.

## How can a Ruby on Rails expert learn SQL

Nowadays, there are plenty of courses and books available on the subject. So it’s hard to recommend specific resources. You can choose whatever you like and suits your learning style.

But, if you are like me and prefer hands-on learning, you might find the following resource helpful -  [https://pgexercises.com/](https://pgexercises.com/){:ref="nofollow" target="_blank"}.

You might also find this article I wrote previously interesting - [Financial plan on PostgreSQL](https://blog.widefix.com/financial-plan-on-postgresql/).
