---
layout: post
title: "The Importance of Understanding the What and Why in Software Development"
headline: "The Importance of Understanding the What and Why in Software Development"
modified: 2024-11-28 18:24:48 +0100
description: "Some description goes here."
tags: ["growing", "software development"]
featured_post: false
toc: true
image: what-and-why-critical-thinking.jpg
---

# Understanding the "What" and "Why" in Software Development: A Mentorship Story

In software development, it’s crucial to understand not just *what* you're doing, but also *why* you're doing it. This simple but essential concept is often overlooked by junior developers, which can lead to incomplete or incorrect implementations. Let me share a story from my experience mentoring a junior developer, where this principle proved pivotal.

![Accounting](/images/accounting.jpg)

## The Task: Implementing a Refund Operation

A junior developer I was mentoring had to implement a refund operation in Sage, an accounting software. The task seemed straightforward: reverse the related payment transaction when a refund is issued. However, instead of questioning the broader context, the developer simply reverted the payment transaction in the code.

### What Went Wrong?

While the payment was reversed, the outcome didn’t align with the requirements. Specifically:
- **The invoice remained in a "paid" status**, which was incorrect after a refund.
- **The payment wasn’t marked as refunded**, leaving the system in an inconsistent state.

The developer was satisfied with the outcome, claiming that the job was complete. This led to a key realization: they had focused solely on the *what*—reverting the transaction—without understanding the *why* behind the operation.

### Why It Happened

This issue stemmed from the developer’s failure to fully grasp the business logic behind the refund operation. In addition to reversing the payment, the invoice needed to reflect its refunded status, and the payment itself should be marked as refunded for accurate reporting.

The key to solving this problem wasn’t just about fixing the code; it was about understanding the purpose behind the refund operation. That meant clarifying the inputs (e.g., refund amount, invoice ID) and expected outputs (e.g., updated invoice and payment statuses).

## The Lesson: Understanding *What* and *Why*

This situation highlighted the importance of understanding both the *what* and *why* when developing software. It's not enough to implement a feature or operation based on surface-level requirements. Developers must dive deeper into:
- **What the operation actually does**: Reversing a payment is only part of the solution.
- **Why it needs to be done this way**: The operation impacts multiple entities (invoice, payment, accounting) and must maintain system consistency.

By emphasizing these two aspects, developers can ensure their work aligns with business goals, prevents errors, and creates more reliable software.

## Mentoring Junior Developers

As a mentor, this was a perfect opportunity to reinforce the importance of understanding the business logic behind every operation. I walked the developer through the full process, from understanding the input/output flow to ensuring that all related statuses and records were updated correctly.

The lesson here was clear: developers should never assume that completing the technical task means the job is done. They need to take the time to understand the broader implications of their work.

## Conclusion

In conclusion, understanding both the *what* and the *why* is fundamental to effective software development. This approach prevents incomplete implementations and ensures that code contributes to the broader goals of the system. By asking the right questions and considering the full scope of a task, developers can create more robust, efficient, and maintainable software.
