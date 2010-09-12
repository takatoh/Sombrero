require 'boot'

class TagType < Sequel::Model
  one_to_many :tags

end

