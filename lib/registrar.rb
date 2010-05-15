#
#  PhotoRegistrar  -  Register to database and store to filesystem.
#

require 'rubygems'
require 'rmagick'
require 'fileutils'
require 'tempfile'
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


  def clip(photo)
    fname = ""
    c = FileFetcher.fetch(photo[:url], :ignore_media_type => @options[:ignore_media_type])
    fname = File.join("./tmp", c[:filename])
    File.open(fname, "wb"){|f| f.write(c[:body])}

    post(fname, photo)
  end


  def post(file, info)
    img = Magick::Image.read(file).first
    width = img.columns
    height = img.rows
    raise Rejection.new("Small photo(#{width}x#{height})") if small_image?(width, height)

    content = File.open(file, "rb"){|f| f.read}
    md5 = Digest::MD5.hexdigest(content)
    raise Rejection.new("Already exist(#{md5})") if Photo.find(:md5 => md5)

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
    post = Post.create({
      :url            => info[:url],
      :page_url       => info[:page_url],
      :posted_date    => Time.now
    })
    post.photo = photo
    post.save
    img = nil
    FileUtils.rm(file)
    photo
  rescue Rejection
    FileUtils.rm(file) if File.exist?(file)
    raise
#  rescue => err
#  ensure
#    FileUtils.rm(fname) if File.exist?(fname)
  end


##
  private

  def small_image?(w, h)
    w < 200 or h < 200
  end


end   # of class PhotoRegistrar

