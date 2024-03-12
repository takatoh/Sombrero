#require 'boot'
require "digest"

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


  def url_posted?(url)
    posts.map{|p| p.url }.include?(url)
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
    return [] if tagnames.nil? || /\A *\z/ =~ tagnames
    tags = tagnames.split(/ +/)
    tags.map{|tag| add_tag(tag)}.compact
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

  def calc_sha256
    if self.sha256.nil?
      photo_path = File.join(SOMBRERO_CONFIG["storage"], self.path)
      content = File.open(photo_path){|f| f.read }
      sha256 = Digest::SHA256.hexdigest(content)
      self.sha256 = sha256
      self.save
      sha256
    else
      nil
    end
  end

  def has_ext?
    !(File.extname(self.path).empty?)
  end

  def put_ext(extname)
    storage = PhotoStorage.new(SOMBRERO_CONFIG["storage"])
    path = storage.put_ext(self.path, extname)
    self.path = path
    self.save
    path
  end

end

