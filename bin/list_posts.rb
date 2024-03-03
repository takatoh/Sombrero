require "./boot"
require "model"


def main
  posts = Post.order_by("id").all

  posts.each do |post|
    puts "#{post.id}"
    puts "  url:      #{post.url}"
    puts "  page url: #{post.page_url}"
    puts "  file:     #{post.photo.path}"
    puts "  tags:     #{post.photo.taggings.map{|t| t.tag.name}.join(' ')}"
  end
end



main
