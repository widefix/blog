---
layout: post
title: "Ask Google to recrawl your URLs"
modified: 2023-01-31 10:01:28 +0100
description: "Learn how to request Google to recrawl your URLs for better website indexing and improved search engine rankings. Follow our step-by-step guide for a successful recrawl."
keywords: "ask google to recrawl,google scan,ask google to recrawl a link,ask google to recrawl my website,ask google to recrawl site,ask google to recrawl your urls,google search console,google search"
image: crawler.png
---

A commonly suggested recommendation from many SEO specialists is as follows:

>  You can request Google to recrawl your website by following these steps:
>
>  1. Verify your website ownership in Google Search Console
>  2. Submit your sitemap to Google through the Search Console
>  3. Fetch as Google feature in the Search Console to request indexing of individual pages
>  4. Use the "Submit URL" feature in Google Search Console for new or updated pages
>  5. Monitor your website's performance in the Search Console to track indexing status.
>
>  Note: Recrawling may take several days or weeks, and it is not guaranteed to happen immediately.

All of that is correct. Unfortunately, in practice, one might encounter the following scenario:

- A page was indexed by Google a long time ago.
- The sitemap was submitted recently.
- Submitting all the pages one by one would take too much time, so it was not done.
- Several weeks have passed, but the page has still not been reindexed.

If you face this issue, the automated option is available. This article includes an example of how **to request Google to reindex a group of URLs** using the **Ruby programming language**.

First, register your project in the Google API Console and obtain a JSON private key file. Follo [these instructions](https://developers.google.com/search/apis/indexing-api/v3/prereqs){:ref="nofollow" target="_blank"} on how to do so.

Next, with the preparation step complete, we move on to the scripting. Let's say we have a list of artists and songs that need to be reindexed. The following Ruby script will schedule their reindex in a bulk request, meaning it will make only one HTTP request instead of multiple. The script implies  [google-api-ruby-client gem](https://github.com/googleapis/google-api-ruby-client){:ref="nofollow" target="_blank"} installed.

```ruby
require 'google/apis/indexing_v3'
require 'googleauth'

api = Google::Apis::IndexingV3::IndexingService.new

# uncomment the line below to see more details
# Google::Apis.logger.level = Logger::DEBUG

api.authorization =
  Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open(Rails.root.join('config/google-api-creds.json')),
    scope: 'https://www.googleapis.com/auth/indexing'
  )

api.authorization.fetch_access_token!

# all published songs and all artists will be scheduled to reindex by Google
api.batch do |batch|
  Song.published.find_each do |song|
    url =
      Google::Apis::IndexingV3::UrlNotification.new(
        url: "https://mysite.com/songs/#{song.id}",
        type: 'URL_UPDATED'
      )
    batch.publish_url_notification(url)
  end
  Artist.find_each do |artist|
    url =
      Google::Apis::IndexingV3::UrlNotification.new(
        url: "https://mysite.com/artists/#{artist.id}",
        type: 'URL_UPDATED'
      )
    batch.publish_url_notification(url)
  end
end
```

Assuming the script is saved in `scripts/google.rb` in a typical Rails application and the private key JSON file is located in `config/google-api-creds.json`, it can be run with the following command:

```shell
rails runner scripts/google.rb
```

This will reschedule all links at once. However, keep in mind that Google has a default quota of 200 requests per day, which can be increased if necessary. More information can be found [here](https://developers.google.com/search/apis/indexing-api/v3/quota-pricing){:ref="nofollow" target="_blank"}.

Additionally, we can verify that the links were requested to be updated using a script. The following code will go through all entities and check when they were requested for recrawling by Google. The results will be saved in the `urls.csv` file.

```ruby
require 'google/apis/indexing_v3'
require 'googleauth'

api = Google::Apis::IndexingV3::IndexingService.new

# uncomment the line below to see more details
# Google::Apis.logger.level = Logger::DEBUG

api.authorization =
  Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open(Rails.root.join('config/google-api-creds.json')),
    scope: 'https://www.googleapis.com/auth/indexing'
  )

api.authorization.fetch_access_token!

require 'csv'

CSV.open('urls.csv', 'wb') do |csv|
  Song.published.find_each do |song|
    url = "https://mysite.com/songs/#{song.id}"
    res = api.get_url_notification_metadata(url: url)
    csv << [song.id, res.url, res.latest_update&.notify_time]
  end
  Artist.find_each do |artist|
    url = "https://mysite.com/artists/#{artist.id}"
    res = api.get_url_notification_metadata(url: url)
    csv << [artist.id, res.url, res.latest_update&.notify_time]
  end
end
```

By scheduling your pages for Google recrawl in this manner, the pages will appear in Google much faster and you won't have to wait for weeks or even months.

For more information and details on how it works, see [here](https://developers.google.com/search/apis/indexing-api/v3/quickstart){:ref="nofollow" target="_blank"}. Also, note that there are other programming languages available for this type of scripting. A list of available libraries for other programming lagunages can be found on the [official page](https://developers.google.com/search/apis/indexing-api/v3/libraries){:ref="nofollow" target="_blank"}.

If you have questions or need a script like this for your project, feel free to [contacting us](https://widefix.com/).
