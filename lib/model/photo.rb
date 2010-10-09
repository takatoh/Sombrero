require 'boot'

class Photo < Sequel::Model
  one_to_many :posts
  one_to_many :taggings

  def before_destroy
    self.posts.each do |post|
      post.delete
    end
  end


  def delete_if_no_posts
    self.destroy if posts.empty?
  end

  def add_tag(tagname)
    tag = Tag.find(:name => tagname) || Tag.new(:name => tagname).save
    unless taggings.map{|tgng| tgng.tag.name}.include?(tag.name)
      tagging = Tagging.new(:tag_id => tag.id, :photo_id => self.id).save
      taggings << tagging
      tag.taggings << tagging
      tag
    else
      nil
    end
  end

  def add_tags(tagnames)
    return 0 if tagnames.nil? || /\A *\z/ =~ tagnames
    tags = tagnames.split(/ +/)
    tags.map{|tag| add_tag(tag)}.compact.size
  end

  def delete_tag(tagname)
    tagging = taggings.select{|t| t.tag.name == tagname}.first
    if tagging
      tagging.delete
    end
    refresh
  end

  def update_tags(tagnames)
    tagnames = tagnames.split(/ +/)
    tagnames0 = taggings.map{|t| t.tag.name}
    (tagnames - tagnames0).each{|t| add_tag(t)}
    (tagnames0 - tagnames).each{|t| delete_tag(t)}
    taggings.map{|t| t.tag}
  end

end

