#
#  PhotoRegistrar  -  Register to database and store to filesystem.
#
#  options:
#    :ignore_media_type
#    :keep
#    :force


require 'rubygems'
require 'rmagick'
require 'fileutils'
require 'pathname'
require 'digest/md5'

require 'boot'
require 'model'
require 'file_fetcher'
require 'photo_storage'


class PhotoRegistrar

  class Rejection < StandardError; end


  def initialize(options = {})
    @options = options
  end


  def clip(photo_info)
    c = FileFetcher.fetch(photo_info[:url], :ignore_media_type => @options[:ignore_media_type])
    fname = Pathname.new("./tmp") + c[:filename].sub(/\?.+\z/, "")
    File.open(fname, "wb"){|f| f.write(c[:body])}

    post(fname, photo_info)
  end


  def post(file, photo_info)
    file = Pathname.new(file) if file.instance_of?(String)
    img = Magick::Image.read(file).first
    width = img.columns
    height = img.rows
    raise Rejection.new("Small photo(#{width}x#{height})") if small_image?(width, height)

    content = File.open(file, "rb"){|f| f.read}
    md5 = Digest::MD5.hexdigest(content)

    photo =  Photo.find(:md5 => md5)
    if photo
      if !(@options[:force]) || photo.posts.map{|p| p.url}.include?(photo_info[:url])
        raise Rejection.new("Already exist(#{md5})")
      end
    else
      storage = PhotoStorage.new(SOMBRERO_CONFIG["storage"])
      path, thumbnail_path, sample_path = storage.store(content, md5 + File.extname(file))
      photo = Photo.create({
        :width          => width,
        :height         => height,
        :filesize       => content.size,
        :md5            => md5,
        :path           => path,
        :sample_path    => sample_path,
        :thumbnail_path => thumbnail_path,
        :posted_date    => Time.now
      })
    end
    photo.add_tags(photo_info[:tags])
    photo.save

    post = Post.create({
      :url            => photo_info[:url],
      :page_url       => photo_info[:page_url],
      :posted_date    => Time.now
    })
    post.photo = photo
    post.save
    img = nil
    FileUtils.rm(file) unless @options[:keep]
    photo
  rescue Rejection
    FileUtils.rm(file) if file.exist? && !@options[:keep]
    raise
  end



  private

  def small_image?(w, h)
    w < SOMBRERO_CONFIG["minimum_photo_width"] or h < SOMBRERO_CONFIG["minimum_photo_height"]
  end


end   # of class PhotoRegistrar

