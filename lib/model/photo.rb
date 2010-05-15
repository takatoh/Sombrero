require 'boot'

class Photo < Sequel::Model
  one_to_many :posts
end

