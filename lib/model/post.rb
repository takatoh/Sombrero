require 'boot'

class Post < Sequel::Model
  many_to_one :photo

  def date
    self.posted_date.strftime("%Y-%m-%d %H:%M:%S")
  end
end

