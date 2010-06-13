require 'boot'

class Tag < Sequel::Model
  one_to_many :taggings

end

