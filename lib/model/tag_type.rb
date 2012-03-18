require 'boot'

class TagType < Sequel::Model
  one_to_many :tags

  def to_s
    self.name
  end
end

