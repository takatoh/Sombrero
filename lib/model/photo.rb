require 'boot'

class Photo < Sequel::Model
  ont_to_many :posts
end

