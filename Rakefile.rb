require "rubygems"
require "bundler/setup"
require "stringex"

## -- Config -- ##

posts_dir       = "_posts"    # directory for blog files
new_post_ext    = "md"  # default new post file extension when using the new_post task
new_page_ext    = "md"  # default new page file extension when using the new_page task


#############################
# Create a new Post or Page #
#############################

# usage rake new_post
desc "Create a new post in #{posts_dir}"
task :new_post, :title do |t, args|
  if args.title
    title = args.title
  else
    title = get_stdin("Enter a title for your post: ")
  end
  filename = "#{posts_dir}/#{Time.now.strftime('%Y-%m-%d')}-#{title.to_url}.#{new_post_ext}"
  if File.exist?(filename)
    abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
  end
  tags = get_stdin("Enter tags to classify your post (comma separated): ")
  puts "Creating new post: #{filename}"
  open(filename, 'w') do |post|
    post.puts "---"
    post.puts "layout: post"
    post.puts "title: \"#{title.gsub(/&/,'&amp;')}\""
    post.puts "headline: \"#{title.gsub(/&/,'&amp;')}\""
    post.puts "modified: #{Time.now.strftime('%Y-%m-%d %H:%M:%S %z')}"
    post.puts "description: \"Some description goes here.\""
    post.puts "tags: [#{tags}]"
    post.puts "featured_post: false"
    post.puts "toc: true"
    post.puts "image:"
    post.puts "---"
  end
end

# usage rake featured_post
desc "Set the featured post"
task :featured_post do |t|
  title = get_stdin("Enter the whole title of post you want to be featured: ")
  posts = Dir.children(posts_dir)

  if posts.select { |file| file.include?(title.to_url) }.empty?
    abort("rake aborted! The #{title} file doesn't exist")
  end

  posts.each do |file|
    file = "#{posts_dir}/#{file}"
    content = File.readlines(file)
    if content[6].match("featured_post: true")
      puts "Discard post: \"#{file}\" as featured"
      content.delete_at(6)
      File.open(file, 'w+') do |f|
        f.puts(content)
      end
    end
  end

  posts.each do |file|
    file = "#{posts_dir}/#{file}"
    content = File.readlines(file)
    if file.match(title.to_url)
      puts "Assign post: \"#{file}\" as featured"
      content = File.readlines(file)
      content.insert(6, "featured_post: true")
      File.open(file, 'w+') do |f|
        f.puts(content)
      end
    end
  end
end

# usage rake new_page
desc "Create a new page"
task :new_page, :title do |t, args|
  if args.title
    title = args.title
  else
    title = get_stdin("Enter a title for your page: ")
  end
  filename = "#{title.to_url}.#{new_page_ext}"
  if File.exist?(filename)
    abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
  end
  tags = get_stdin("Enter tags to classify your page (comma separated): ")
  puts "Creating new page: #{filename}"
  open(filename, 'w') do |page|
    page.puts "---"
    page.puts "layout: page"
    page.puts "permalink: /#{title.to_url}/"
    page.puts "title: \"#{title}\""
    page.puts "modified: #{Time.now.strftime('%Y-%m-%d %H:%M')}"
    page.puts "tags: [#{tags}]"
    page.puts "image:"
    page.puts "  feature: "
    page.puts "  credit: "
    page.puts "  creditlink: "
    page.puts "share: "
    page.puts "---"
  end
end

def get_stdin(message)
  print message
  STDIN.gets.chomp
end

def ask(message, valid_options)
  if valid_options
    answer = get_stdin("#{message} #{valid_options.to_s.gsub(/"/, '').gsub(/, /,'/')} ") while !valid_options.include?(answer)
  else
    answer = get_stdin(message)
  end
  answer
end
