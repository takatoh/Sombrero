#require 'boot'
require 'sequel'
require 'sequel/extensions/pagination'

class Post < Sequel::Model
  many_to_one :photo

  def after_destroy
    photo.delete_if_no_posts
  end


  def date
    self.posted_date.strftime("%Y-%m-%d")
  end

  def datetime
    self.posted_date.strftime("%Y-%m-%d %H:%M:%S")
  end

  def extname
    ext = File.extname(self.url)
    if ext.empty?
      ext = /format=([a-z]+)/.match(self.url)[1]
    end
    ext
  end
end

