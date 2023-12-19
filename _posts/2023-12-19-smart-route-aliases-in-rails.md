---
layout: post
title: "Smart route aliases in Rails"
headline: "Smart routes aliases in Rails"
modified: 2023-12-19 18:00:50 +0100
description: "Learn how to define smart aliases in Rails router."
tags: [rails]
featured_post: false
image: route-66.jpg
---

For search engine optimization and marketing purposes, a Rails project may require the definition of an alias route. This can be challenging if the original route contains a dynamic component that depends on the current user's session.

In our project, we sought to create an easy shorthand `/edit_my_plans` for the user-specific route `/users/:id/edit?tab=plans`.

For instance, Rails provides a mechanism to define this type of redirect using the following syntax (the code example is extracted from their official documentation):

```ruby
get '/stories/:name', to: redirect { |path_params, req| "/articles/#{path_params[:name].pluralize}" }
```

Employing this knowledge, we devised a clean and legible approach to defining this type of route, incorporating business logic of any complexity directly within the router:

```ruby
# in config/routes.rb:
get "/edit_my_plans", to: redirect(RoutesAlias.edit_my_plans)
```

And this is the dedicated service class, aptly named `RoutesAlias`, which encapsulates the intricate business logic. It's more judicious to isolate such intricate operations into a separate class, rather than embedding them within the router definition. We've placed it in the `app/lib` directory, though in your specific project, you may choose a different location:

```ruby
class RoutesAlias
  include Rails.application.routes.url_helpers

  attr_reader :session

  def self.edit_my_plans
    proc { |_params, request| new(request.session).edit_my_plans }
  end

  def initialize(session)
    @session = session
  end

  def edit_my_plans
    current_user = Authentication.user_from_session(session)

    case current_user&.user_type
    when "vendor"
      edit_user_path(current_user, tab: "plans")
    when "user"
      projects_path
    when nil
      "/auth/auth0?origin=/edit_my_plans"
    end
  end
end
```

Now, marketing sites, such as landing pages or others, can effortlessly utilize the generic URL `/edit_my_plans`. Rails will orchestrate the redirection to the appropriate route, whether it's a login form or a specific homepage tailored for distinct user types.

I hope this assists in your Rails project. Happy coding!
