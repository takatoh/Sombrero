#! ruby -Ku

require 'boot'
require 'model'

posts = Post.order_by("id").all

posts.each do |p|
  puts "- url: #{p.url}"
  puts "  page_url: #{p.page_url}"
  puts "  file: #{p.photo.path}"
  puts "  tags: #{p.photo.taggings.map{|t| t.tag.name}.join(' ').inspect}"
end
