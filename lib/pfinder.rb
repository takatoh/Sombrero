#
# PFinder
#

require 'find'
require 'image_types'


class PFinder

  include ImageTypes

  def initialize(dir)
    @dir = dir
    @photos = []
  end

  def find
    Find.find(@dir) do |f|
      @photos << f if File.file?(f) && included_type?(f)
    end
    @photos.map!{|p| { :image_url => p, :page_url => nil }}
  end

end   # of PFinder

