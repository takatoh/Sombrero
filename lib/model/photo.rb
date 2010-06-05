require 'boot'

class Photo < Sequel::Model
  one_to_many :posts

  def before_destroy
    self.posts.each do |post|
      post.delete
    end
  end


  def delete_if_no_posts
    self.destroy if posts.empty?
  end

end

