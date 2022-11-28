---
layout: post
title: "Keep DB schema clean and consistent between branches"
modified: 2022-11-28 00:41:06 +0300
description: "Learn how to keep DB schema clean and consistent between branches while develop a Rails application"
tags: [rails, migrations]
comments: true
share: true
image: actual_db_schema.jpg
---

Switching between branches with migrations run for a Rails application causes the DB state inconsistent.
Eventually, the application starts raising exceptions coming from database and you start debugging.
You spend much time on that and turns out some migrations from not merged branch needs to be rolled back. Does that sound familiar to you? Keep reading to see a solution that solves this issue once and forever (well, with some caveats).
