---
layout: post
title: "Select unique latest grouped records from DB"
headline: "Select unique latest grouped records from DB"
modified: 2023-07-13 17:26:54 +0200
description: "Learn a technique that allows you to build a recent records block in a Ruby on Rails application."
tags: [sql, active_record]
featured_post: false
toc: true
image: unique-grouped.jpg
---

Nowadays, almost every Ruby on Rails application has a so-called recent records block.
This block usually shows statistics or a list of recent things within the project during the last few days searched by some criteria.
It can be something like "top 10 products", "the most popular projects", or "the most relevant apartments". Read this blog post the learn how to efficiently build data for these blocks using SQL and window functions in Ruby on Rails app.

## Recent records - the task overview

Assume that you've got an app that has `Project` model. It has many `ratings`. The `Rating` model has just a value from 1 to 5 assigned by users to some projects.

For the task understanding it's enough to have a look into the table definition:

```sql
db-# \d ratings
                                          Table "public.ratings"
   Column    │              Type              │ Collation │ Nullable │               Default
═════════════╪════════════════════════════════╪═══════════╪══════════╪═════════════════════════════════════
 id          │ bigint                         │           │ not null │ nextval('ratings_id_seq'::regclass)
 reviewer_id │ bigint                         │           │          │
 reviewee_id │ bigint                         │           │          │
 rating      │ integer                        │           │          │
 review      │ text                           │           │          │
 project_id  │ bigint                         │           │          │
 created_at  │ timestamp(6) without time zone │           │ not null │
 updated_at  │ timestamp(6) without time zone │           │ not null │
Indexes:
    "ratings_pkey" PRIMARY KEY, btree (id)
```

This table has the following data:

```sql
db-# select id, reviewer_id, reviewee_id, rating, project_id, created_at from ratings;
 id │ reviewer_id │ reviewee_id │ rating │ project_id │         created_at
════╪═════════════╪═════════════╪════════╪════════════╪════════════════════════════
  8 │           9 │          10 │      5 │         27 │ 2022-12-05 21:46:01.583185
 12 │           7 │           6 │      5 │         26 │ 2022-12-23 14:35:11.047002
 13 │           6 │           7 │      5 │         26 │ 2022-12-23 14:36:48.366411
 18 │           9 │          10 │      5 │         39 │ 2023-03-01 23:27:52.68548
 19 │          10 │           9 │      5 │         39 │ 2023-03-01 23:28:32.880234
 20 │           9 │          10 │      5 │         86 │ 2023-03-01 23:35:15.564763
(6 rows)
```

Our task is to return the latest reviews per project. So the resulting records should be these:

```sql
 id │ reviewer_id │ reviewee_id │ rating │ project_id │         created_at
════╪═════════════╪═════════════╪════════╪════════════╪════════════════════════════
  8 │           9 │          10 │      5 │         27 │ 2022-12-05 21:46:01.583185
 13 │           6 │           7 │      5 │         26 │ 2022-12-23 14:36:48.366411
 19 │          10 │           9 │      5 │         39 │ 2023-03-01 23:28:32.880234
 20 │           9 │          10 │      5 │         86 │ 2023-03-01 23:35:15.564763
(4 rows)
```

Note the project_id is distinct compared to the all records. And the timestamps are the most recent for those duplicated projects (their id = 26, 39).

There is no way to solve this task efficiently using only ActiveRecord functionality and pure Ruby. But SQL can solve this with the [window function](https://www.postgresql.org/docs/current/tutorial-window.html){:ref="nofollow" target="_blank"} technique.

## How window function with row number partition works

The idea is the following - we rank all records inside the table from 1 no N for the duplicated records of our search criteria. The most recent record gets 1, older one gets higher rank. The distinct rows will have 1.

For example:

```sql
 id │ project_id │ reviewee_id │         created_at         │ row_number
════╪════════════╪═════════════╪════════════════════════════╪════════════
  8 │         27 │          10 │ 2022-12-05 21:46:01.583185 │          1
 12 │         26 │           6 │ 2022-12-23 14:35:11.047002 │          2
 13 │         26 │           7 │ 2022-12-23 14:36:48.366411 │          1
 18 │         39 │          10 │ 2023-03-01 23:27:52.68548  │          2
 19 │         39 │           9 │ 2023-03-01 23:28:32.880234 │          1
 20 │         86 │          10 │ 2023-03-01 23:35:15.564763 │          1
(6 rows)
```

The ratings with id = 8, 20 receive row number 1 because these projects are distinct (27, 86). But projects with id = 26, 39 have several ratings that's why the rows with this project id have row_number 1 and 2. The most recent ratings per project receive 1, and the older ones receive row number 2.

## Use subselect to filter correct results

If we filter out those row numbers greater 1 we get the required result. If that would be a table we could use the SQL's `where` clause. For example, a view (virtual table) could be created for that. But we will keep it simple. We will use subselect: initially we prepare select to return the data as above and immediately use `select` statement to filter out the correct result.

But first, let's see how to write SQL statement to assign the row number using the already noticed **window function**:

```sql
db-# select
        id,
        project_id,
        reviewee_id,
        created_at,
        row_number() over (partition by project_id order by created_at desc)
        from ratings
        order by created_at;

 id │ project_id │ reviewee_id │         created_at         │ row_number
════╪════════════╪═════════════╪════════════════════════════╪════════════
  8 │         27 │          10 │ 2022-12-05 21:46:01.583185 │          1
 12 │         26 │           6 │ 2022-12-23 14:35:11.047002 │          2
 13 │         26 │           7 │ 2022-12-23 14:36:48.366411 │          1
 18 │         39 │          10 │ 2023-03-01 23:27:52.68548  │          2
 19 │         39 │           9 │ 2023-03-01 23:28:32.880234 │          1
 20 │         86 │          10 │ 2023-03-01 23:35:15.564763 │          1
(6 rows)
```

The `row_number() over (partition by project_id order by created_at desc)` is a window function that assigns row number from 1 to N for the records duplicated by some criteria. In this case the criteria is distinct project_id sorted by created_at desc.

Running this query inside DB console will produce the result above.

Wrap this `select` with another `select` and filter only rows with number = 1:

```sql
db-# select
  id,
  reviewer_id,
  reviewee_id,
  rating,
  project_id,
  created_at from (
    select *, row_number() over (partition by project_id order by created_at desc)
    from ratings
    order by created_at
  )
  as ratings where row_number = 1;

 id │ reviewer_id │ reviewee_id │ rating │ project_id │         created_at
════╪═════════════╪═════════════╪════════╪════════════╪════════════════════════════
  8 │           9 │          10 │      5 │         27 │ 2022-12-05 21:46:01.583185
 13 │           6 │           7 │      5 │         26 │ 2022-12-23 14:36:48.366411
 19 │          10 │           9 │      5 │         39 │ 2023-03-01 23:28:32.880234
 20 │           9 │          10 │      5 │         86 │ 2023-03-01 23:35:15.564763
(4 rows)
```

Voila, we've got what we want!

## Use ActiveRecord.from to return the results as Ruby objects

Since we've got the SQL query it's easy to port it into ActiveRecord and get eventually the list of Ruby objects. We will use the `ActiveRecord.from` to write the subselect:

```ruby
> Rating
  .select("id, reviewer_id, reviewee_id, rating, project_id, created_at")
  .from("(select *, row_number() over (partition by project_id order by created_at desc) from ratings group by project_id, reviewee_id, created_at, id order by created_at) as ratings")

  Rating Load (41.9ms)  SELECT id, reviewer_id, reviewee_id, rating, project_id, created_at FROM (select *, row_number() over (partition by project_id order by created_at desc) from ratings group by project_id, reviewee_id, created_at, id order by created_at) as ratings WHERE "ratings"."row_number" = $1  [["row_number", 1]]
=> [#<Rating:0x000000011190d410 id: 8, reviewer_id: 9, reviewee_id: 10, rating: 5, project_id: 27, created_at: Mon, 05 Dec 2022 21:46:01.583185000 UTC +00:00>,
 #<Rating:0x000000011190d348 id: 13, reviewer_id: 6, reviewee_id: 7, rating: 5, project_id: 26, created_at: Fri, 23 Dec 2022 14:36:48.366411000 UTC +00:00>,
 #<Rating:0x000000011190d280 id: 19, reviewer_id: 10, reviewee_id: 9, rating: 5, project_id: 39, created_at: Wed, 01 Mar 2023 23:28:32.880234000 UTC +00:00>,
 #<Rating:0x000000011190d1b8 id: 20, reviewer_id: 9, reviewee_id: 10, rating: 5, project_id: 86, created_at: Wed, 01 Mar 2023 23:35:15.564763000 UTC +00:00>]
```

You can run this experiment yourself on this [demo app](https://github.com/widefix/demo-fast-sql){:ref="nofollow" target="_blank"}.

## Conclusion

Advanced SQL understanding allows you to write performant advanced functionality in a Ruby on Rails application efficiently.

If you like this article and would like to see more examples of how SQL can improve your software development life read these articles:

  - [Make your Ruby on Rails app 80x faster with SQL](https://blog.widefix.com/importance-sql-for-rails-experts/){:ref="nofollow" target="_blank"}
  - [Financial plan on PostgreSQL](https://blog.widefix.com/financial-plan-on-postgresql/){:ref="nofollow" target="_blank"}
  - [Financial plan on Rails](https://blog.widefix.com/financial-plan-on-rails/){:ref="nofollow" target="_blank"}
  - [From Single drop-down to Multiple check-boxes](https://blog.widefix.com/from-single-dd-to-multiple-checkboxes/){:ref="nofollow" target="_blank"}
  - [Efficient algorithm to check dates overlap](https://blog.widefix.com/date-ranges-overlap/){:ref="nofollow" target="_blank"}

Have a good day ahead and happy coding!
