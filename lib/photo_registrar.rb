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
require 'digest/md5'

require 'boot'
require 'model/photo'
require 'model/post'
require 'file_fetcher'
require 'photo_storage'


class PhotoRegistrar

  class Rejection < StandardError; end


  def initialize(options = {})
    @options = options
  end


  def clip(photo_info)
    fname = ""
    c = FileFetcher.fetch(photo_info[:url], :ignore_media_type => @options[:ignore_media_type])
    fname = File.join("./tmp", c[:filename])
    File.open(fname, "wb"){|f| f.write(c[:body])}

    post(fname, photo_info)
  end


  def post(file, photo_info)
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
    FileUtils.rm(file) if File.exist?(file) && !@options[:keep]
    raise
  end



  private

  def small_image?(w, h)
    w < 200 or h < 200
  end


end   # of class PhotoRegistrar

