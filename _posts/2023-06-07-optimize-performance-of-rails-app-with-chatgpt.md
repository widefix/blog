---
layout: post
title: "Optimize Rails app performance with ChatGPT"
headline: "See how ChatGPT is good with code refactoring or performance optimization"
modified: 2023-06-07 18:30:34 +0200
description: "Learn how to use ChatGPT in order to optimize your Rails app performance by code refactoring from Ruby to SQL."
tags: [chatgpt, sql, postgresql, performance, active_record]
featured_post: false
toc: true
image: rocket-launch.jpg
---

The previous article [Make your Ruby on Rails app 80x faster with SQL](https://blog.widefix.com/importance-sql-for-rails-experts/){:ref="nofollow" target="_blank"} shows how SQL knowledge can help to optimize your Rails application performance. We discussed it within [Belarus User Group](https://www.brug.by/){:ref="nofollow" target="_blank"} community. Not everyone agreed with the point and didn’t find SQL knowledge a good asset for investment. That's something expected. There is no revelation here. But that meeting had something that everyone was impressed with. We experimented and found out how ChatGPT is good with code optimization. We saw how it transforms Ruby code into performant SQL. The results were great. Check that out within this article.

## ChatGPT request to transform Ruby code into SQL

As before, we are going to use this [experimental repository](https://github.com/widefix/demo-fast-sql){:ref="nofollow" target="_blank"}.

We took [the following code snippet](https://github.com/widefix/demo-fast-sql/blob/4ea63b68d4404403e543b1d09978e5cdd5742f36/app/queries/services_stats_query.rb#L31-L64){:ref="nofollow" target="_blank"}, the slowest and original version, and asked to improve its performance by rewriting it into SQL:

```ruby
# the original code

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
```

And we got the following response from ChatGPT:

```ruby
SELECT
  c1.id AS category_id,
  c2.name AS category_name,
  c1.name AS subcategory_name,
  COUNT(DISTINCT p.id) FILTER (WHERE p.status = 'Complete') AS completed_projects_count,
  COUNT(r.id) AS ratings_count,
  COALESCE(AVG(r.rating), 0) AS ratings_average
FROM
  services s
  JOIN categories c1 ON s.category_id = c1.id
  JOIN categories c2 ON c1.parent_id = c2.id
  LEFT JOIN projects p ON s.user_id = p.vendor_id AND p.category_id = c1.id
  LEFT JOIN ratings r ON s.user_id = r.reviewee_id AND p.id = r.project_id
WHERE
  s.user_id = :user_id AND s.status = 'approved' AND s.active = true
GROUP BY
  c1.id, c2.name, c1.name
ORDER BY
  completed_projects_count DESC, c1.id ASC;
```

And these are the performance measurement results:

```
Warming up --------------------------------------
                ruby     1.000  i/100ms
                 sql    54.000  i/100ms
             sql_gpt    59.000  i/100ms
Calculating -------------------------------------
                ruby      6.846  (±14.6%) i/s -     34.000  in   5.000338s
                 sql    540.320  (± 8.5%) i/s -      2.700k in   5.038711s
             sql_gpt    609.335  (± 6.9%) i/s -      3.068k in   5.059364s

Comparison:
             sql_gpt:      609.3 i/s
                 sql:      540.3 i/s - same-ish: difference falls within error
                ruby:        6.8 i/s - 89.01x  slower
```

We also checked that the result of the query service is the same for both calls. That means there are no bugs in the produced SQL by the AI.

The ChatGPT result is the fastest one. At the same time, no business logic was defective. That's a very good result!

## Should one use ChatGPT to optimize code performance or not

While the AI results are good, it's still doubtful who and how to use the tool. Not seasoned developers might don't understand where the bottleneck is. They would struggle with finding a correct question for ChatGPT. They would not understand how to fix the generated code if it has bugs. Some time later I tried to repeat the experiment and know the machine produced a very different SQL that has bugs inside:

```sql
-- Get average ratings and count for each service
WITH rating_summary AS (
  SELECT p.category_id, COUNT(r.id) AS ratings_count, COALESCE(AVG(r.rating), 0) AS ratings_average
  FROM ratings r
  INNER JOIN projects p ON p.id = r.project_id
  WHERE r.reviewee = <user_id>
  GROUP BY p.category_id
),

-- Get completed projects count for each service
completed_projects AS (
  SELECT category_id, COUNT(*) AS completed_projects_count
  FROM projects
  WHERE vendor = <user_id> AND status = 'Complete'
  GROUP BY category_id
)

-- Combine the results
SELECT
  s.category_id,
  c.name AS category_name,
  p.name AS subcategory_name,
  COALESCE(cp.completed_projects_count, 0) AS completed_projects_count,
  COALESCE(rs.ratings_count, 0) AS ratings_count,
  ROUND(COALESCE(rs.ratings_average, 0), 1) AS ratings_average
FROM services s
JOIN categories c ON c.id = s.category_id
JOIN categories p ON p.id = c.parent_id
LEFT JOIN rating_summary rs ON rs.category_id = s.category_id
LEFT JOIN completed_projects cp ON cp.category_id = s.category_id
WHERE s.user = <user_id> AND s.status = 'approved' AND s.active = true
ORDER BY completed_projects_count DESC;
```

While the AI results are good, it's still doubtful who and how to use the tool. Not seasoned developers might don't understand where the bottleneck is. They would struggle with finding a correct question for ChatGPT. They would not understand how to fix the generated code if it has bugs. Later, I tried to repeat the experiment. This time the machine produced a very different SQL:

```
Warming up --------------------------------------
                ruby     1.000  i/100ms
                 sql    52.000  i/100ms
             sql_gpt    40.000  i/100ms
         sql_gpt_new    38.000  i/100ms
Calculating -------------------------------------
                ruby      5.754  (±17.4%) i/s -     28.000  in   5.039290s
                 sql    433.067  (±20.3%) i/s -      2.080k in   5.029710s
             sql_gpt    561.018  (±14.4%) i/s -      2.760k in   5.044415s
         sql_gpt_new    514.242  (±19.4%) i/s -      2.432k in   5.013023s

Comparison:
             sql_gpt:      561.0 i/s
         sql_gpt_new:      514.2 i/s - same-ish: difference falls within error
                 sql:      433.1 i/s - same-ish: difference falls within error
                ruby:        5.8 i/s - 97.50x  slower
```

However, it's still faster than the original rewrite to SQL.

## Conclusion

ChatGPT is very good at code refactoring and transforming Ruby code into SQL. Even though the results are impressive it still needs an expert communicating with the tool to form a correct question, check the produced results, and fix minor issues. The results can be a good start in code refactoring and optimization.

That was a great meeting. We had a memorable time together. Thanks to everyone who participated. I am looking forward to our weekly calls and I invite everyone to join the community.

Happy coding!
