#!/user/env ruby
# encoding: utf-8

require './boot'
require 'model'

puts "#{Photo.count} photos."
puts "#{Post.count} posts."
