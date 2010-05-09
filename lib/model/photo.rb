require 'boot'

class Photo < Sequel::Model
  def date
    self.posted_date.strftime("%Y-%m-%d %H:%M:%S")
  end
end

