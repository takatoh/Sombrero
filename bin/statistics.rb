#! ruby -Ku

require 'boot'
require 'model'

puts "#{Photo.all.size} photos."
puts "#{Post.all.size} posts."
