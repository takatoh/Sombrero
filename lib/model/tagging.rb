#require 'boot'

class Tagging < Sequel::Model
  many_to_one :tag
  many_to_one :photo
end

