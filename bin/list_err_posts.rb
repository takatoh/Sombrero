require 'boot'
require 'model'

ds = Post.order_by("id")
posts = ds.all

posts.each do |p|
  if p.photo.nil?
    puts "#{p[:id]}:"
    puts "  url:         #{p[:url]}"
    puts "  page url:    #{p[:page_url]}"
    puts "  photo:       #{p.photo.to_s}"
  end
end

