#require 'boot'
require 'sequel'
require 'sequel/extensions/pagination'

class Post < Sequel::Model
  many_to_one :photo

  def after_destroy
    photo.delete_if_no_posts
  end


  def date
    self.posted_date.strftime("%Y-%m-%d %H:%M:%S")
  end
end

