#require 'boot'

class Tag < Sequel::Model
  one_to_many :taggings
  many_to_one :tag_type


  def add_alias(tag)
    if tag.class == String
      tag = Tag.find(:name => tag) || Tag.new(:name => tag).save
    end
    tag.alias_to = self.id
    self.has_alias = true
    tag.save
    self.save
  end

  def remove_alias(alias_tag)
    if alias_tag.class == String
      alias_tag = Tag.find(:name => alias_tag)
    end
    alias_tag.alias_to = nil
    alias_tag.save
    if Tag.find(:alias_to => self.id).nil?
      self.has_alias = false
      self.save
    else
      self
    end
  end

  def aliases
    Tag.filter(:alias_to => self.id).all || []
  end

  def alias_for
    Tag.first(:id => self.alias_to)
  end

  def to_s
    self.name
  end

end

