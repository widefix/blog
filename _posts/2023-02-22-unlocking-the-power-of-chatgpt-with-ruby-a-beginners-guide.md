---
layout: post
title: "Unlocking the Power of ChatGPT with Ruby"
modified: 2023-02-22 22:31:11 +0100
description: "Get started with ChatGPT and Ruby with our beginner-friendly guide, designed to help you unlock the full potential of these powerful tools."
tags: [ruby, chatgpt]
featured_post: false
keywords: "chatgpt, ruby, artificial intelligence, machine learning, programming, beginner's guide, tutorial, integration, workflow, productivity, natural language processing, ai-powered applications, intelligent chatbots, natural language understanding, developer tools"
image: chatgpt.jpg
---

Are you looking to harness the power of artificial intelligence and machine learning to streamline your coding workflow? ChatGPT and Ruby are two powerful tools that can help you do just that. However, if you're new to these tools, getting started can be daunting. That's where our beginner-friendly guide comes in. In this article, we'll take you through everything you need to know to use ChatGPT with Ruby, from the basics of integration to more advanced features. Whether you're a seasoned developer or just starting out, this guide will help you unlock the full potential of these powerful tools and take your coding skills to the next level.

Before you start integrating the ChatGPT API, you need to register for an API key and obtain your credentials from the ChatGPT website. To do that, follow this [page](https://platform.openai.com/account/api-keys){:ref="nofollow" target="_blank"}.

Create the following class in your Ruby On Rails or pure Ruby project:

```ruby
class OpenaiPrompt
  extend Dry::Initializer

  URL = "https://api.openai.com/v1/completions"

  param :prompt

  option :model, default: proc { "text-davinci-003" }
  option :max_tokens, default: proc { 1000 }
  option :temperature, default: proc { 0 }

  def call
    connection =
      Faraday.new do |faraday|
        faraday.ssl[:verify] = false
        faraday.headers = headers
      end
    response = connection.post(URL, body)
    json = JSON.parse(response.body)
    json["choices"].first["text"]
  end

  private

  def body
    {
      model: model,
      prompt: prompt,
      max_tokens: max_tokens,
      temperature: temperature
    }.to_json
  end

  def headers
    {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{ENV['OPENAI_ACCESS_TOKEN']}",
      "OpenAI-Organization" => ENV['OPENAI_ORGANIZATION_ID']
    }
  end
end
```

You can define it in some existing file or create a new one, it doesn't matter. But prefer to have a separate file.
If it's a Rails application, `app/services/openai_prompt.rb` is a good file location for this piece of code.

This class has the following dependencies (gems) that should be added to your Gemfile:
- `faraday` - an abstract an handy library to make HTTP calls
- `dry-initializer` - a library that allows to define the `new` method implicitly without too much repetitive and boring code.

Define the env variable `OPENAI_ACCESS_TOKEN`. The `OPENAI_ORGANIZATION_ID` is optional, it's needed only when you have several organizations registered within ChatGPT.

Then you are ready to use it from any line of you project like that: `OpenaiPrompt.new('Why is Ruby awesome programming language?').call`

Here is an example of its usage in a Rails console:

```ruby
> OpenaiPrompt.new('Why is Ruby awesome programming language?').call
> # => "\n\nRuby is an awesome programming language because it is easy to learn and use, has a large and supportive community, and is highly flexible and powerful. It is also object-oriented, meaning that it allows developers to create complex applications quickly and easily. Additionally, Ruby is open source, meaning that it is free to use and modify. Finally, Ruby is known for its readability, which makes it easier for developers to understand and debug code."
```

If you have questions or need to integrate ChatGPT into your Ruby On Rails or any other Ruby-based project, please [contact](https://widefix.com/).
