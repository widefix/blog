---
layout: post
title: "Use timestamp for predicates in Rails"
headline: "Use timestamp type attribute for predicates in Rails"
modified: 2023-06-15 15:19:16 +0200
description: "Discover the benefits of using timestamp columns over boolean fields in Ruby on Rails and learn a helpful technique for utilizing timestamp columns defined in a Rails application model as predicates."
tags: [rails, active_record, DSL]
featured_post: false
toc: true
image: checklist.jpg
---

## Why use timestamp field instead of boolean for checkbox

You are about to add a new boolean attribute into your model inside a Ruby on Rails application. It's simple as is - add a boolean column in DB and call it a day. But stop and think - consider a timestamp type for the corresponding columns in the database.

This approach allows for tracking the time when the value change. That can be helpful in debugging, especially when dealing with production issues.

Ok, it's preferable to use the timestamp field type on the back-end. But it is still convenient to have a checkbox on the user interface. Thus, the timestamp column type does not match the UI field type (checkbox). That means the value (such as true/false, yes/no, or any other) from the front-end should be transformed into a timestamp or `nil` on the back-end. That's needed, to ensure compatibility with the mass-assignment methods (`.new` or `#update`).

## Avoid code duplicating with a universal solution

One could write this type of transformation logic ad-hoc inside controllers. But you can create a universal solution. One way to achieve this is by defining a helper method in the base model class. In Rails, the base model class is typically `ApplicationRecord`. By doing this, you can ensure its availability across all models in the application. See the following example how to do this:

```ruby
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Defines a predicate method and a setter method for the specified attributes.
  #
  # To use this code in the User model, call the following:
  #   timestamp_as_boolean :muted
  #
  # In this scenario, it assumes that a "muted_at" column is defined in the table.
  # After calling the code, the following methods are defined on the User model:
  #   muted? - checks if a user is muted
  #   muted=(value) - sets the muted_at timestamp if the value is equivalent to boolean "true"
  def self.timestamp_as_boolean(*fields)
    fields.each do |field|
      timestamp_field = "#{field}_at"
      predicate = "#{field}?"
      define_method(predicate) do
        public_send(timestamp_field).present?
      end
      define_method("#{field}=") do |value|
        new_value = ActiveModel::Type::Boolean.new.cast(value) ? Time.current : nil
        public_send("#{timestamp_field}=", new_value) if new_value.nil? || !public_send(predicate)
      end
    end
  end
end
```

We have now implemented a universal solution using some meta-programming techniques in Ruby. Here's how you can use it. Let's take the example of the `User` model and convert the `muted_at` column into a boolean attribute using the following approach:

```ruby
class User < ApplicationRecord
  timestamp_as_boolean :muted
end
```

To utilize this solution in an ERB template on the user interface, follow these steps:

```ruby
<%= form.check_box :muted, { checked: @user.muted? } %>
```

Let's verify its functionality:

```
> user = User.last
> user.muted? # => true
> user.update!(muted: false)
> user.muted? # => false
> user.update!(muted: true) # => true
> user.muted? # => true
> user.muted_at # => Thu, 15 Jun 2023 15:16:54.582848000 UTC +00:00
> user.update!(muted: true) # => true
> user.muted_at # => Thu, 15 Jun 2023 15:16:54.582848000 UTC +00:00
```

It is important to note that after the second assignment of muted = true, the timestamp did not change. This behavior is expected and logical because the value itself was not modified. The purpose of tracking the timestamp is to capture the moment when a change in the value occurs. In this case, since the value remains the same, there is no need for the timestamp to be updated. This behavior aligns with the intended functionality.  It ensures that the timestamp accurately reflects when a change in the value of the attribute occurs.

## Conclusion

Use a timestamp type for columns in the database. Create a universal solution to transform boolean values. As a result, enhance the functionality and debugging capabilities of our models. The timestamp type allows us to track the values change time. That can aid in identifying and troubleshooting issues, particularly in production environments. Avoid code duplication and ensure consistent behavior across models with a universal solution. Metaprogramming can help with that. These improvements contribute to a more robust and efficient application.

Happy coding!
