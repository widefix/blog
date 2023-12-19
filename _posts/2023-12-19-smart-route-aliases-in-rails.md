---
layout: post
title: "Smart route aliases in Rails"
headline: "Smart routes aliases in Rails"
modified: 2023-12-19 18:00:50 +0100
description: "Empower your marketing sites, landing pages, and any other web presence with intelligent URL redirection."
tags: [rails, rails-development]
featured_post: false
image: route-66.jpg
---

Sometimes, for SEO and marketing reasons, you might need to create an alias route in your Rails project. This can get tricky if the original route relies on dynamic elements that change based on the user's session.

In our project, we wanted to create a quick and easy shortcut, `/edit_my_plans`, for the user-specific route `/users/:id/edit?tab=plans`.

For example, Rails offers a way to set up this type of redirect using the following code (taken from their official documentation):

```ruby
get '/stories/:name', to: redirect { |path_params, req| "/articles/#{path_params[:name].pluralize}" }
```

With this knowledge in hand, we developed a clear and straightforward method for defining these types of routes, allowing us to embed business logic of any level of complexity directly into the router:

```ruby
# in config/routes.rb:
get "/edit_my_plans", to: redirect(RoutesAlias.edit_my_plans)
```

This is our special class, called `RoutesAlias`, that handles all the complex stuff. It's better to keep this stuff separate from the router, so we put it in the `app/lib` folder. You can put it somewhere else in your project if you want.

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

Now, marketing sites, like landing pages or other marketing pages, can easily use the generic URL `/edit_my_plans`. Rails will handle everything, taking you to the right place, whether it's a login form, a specific homepage for a particular user type, or something else.

Hope this helps with your Rails project! Happy coding!
