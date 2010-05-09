#
#  PhotoStorage
#

require 'rubygems'
require 'rmagick'
require 'fileutils'
require 'iconv'
require 'uri'
require 'digest/md5'


class PhotoStorage

  def initialize(base_dir)
    @storage_dir   = File.expand_path(base_dir)
    @photo_dir     = "photos"
    @thumbnail_dir = "thumbs"
    @sample_dir    = "samples"
    if defined? PC_PROVIDES_URL
      @provides_url = PC_PROVIDES_URL
    else
      @provides_url = ""
    end
    if defined? PC_ARRANGED_FILE_ENCODING
      @arranged_file_encoding = PC_ARRANGED_FILE_ENCODING
    else
      @arranged_file_encoding = nil
    end
    @format = "jpg"
  end


  def store(content, path)
    fullpath = photo_fullpath(path)
    dir = File.dirname(fullpath)
    unless File.exist?(dir)
      FileUtils.mkdir_p(dir)
    end
    File.open(fullpath, "wb") do |f|
      f.write(content)
    end
    md5 = Digest::MD5.hexdigest(content) + ".#{@format}"
    thumb_path = make_thumbnail(fullpath, {:name => md5})
    sample_path = make_sample(fullpath, {:name => md5})
    [ photo_path(path), thumb_path, sample_path ]
  end


  def make_thumbnail(photopath, opts = {})
    thumbpath = thumb_fullpath(opts[:name])
    return thumb_path(opts[:name]) if File.exist?(thumbpath) and !opts[:force]
    unless File.exist?(File.dirname(thumbpath))
      FileUtils.mkdir_p(File.dirname(thumbpath))
    end
    geometry = Magick::Geometry.from_s("150x150")
    img = Magick::Image.read(photopath).first
    thumbnail = img.change_geometry(geometry) do |cols, rows, i|
      i.resize!(cols, rows)
    end
    thumbnail.write(thumbpath)
    thumb_path(opts[:name])
  end

  def make_sample(photopath, opts = {})
    samplepath = sample_fullpath(opts[:name])
    return sample_path(opts[:name]) if File.exist?(samplepath) and !opts[:force]
    img = Magick::Image.read(photopath).first
    if img.columns > 600 or img.rows > 800
      geometry = Magick::Geometry.from_s("600x800")
      sample = img.change_geometry(geometry) do |cols, rows, i|
        i.resize!(cols, rows)
      end
    else
      sample = img
    end
    sample.write(samplepath)
    sample_path(opts[:name])
  end



  private

  def photo_path(path)
    File.join(@photo_dir, path)
  end

  def photo_fullpath(path)
    File.join(@storage_dir, @photo_dir, path)
  end

  def thumb_path(path)
    File.join(@thumbnail_dir, path.sub(File.extname(path), ".#{@format}"))
  end

  def thumb_fullpath(path)
    File.join(@storage_dir, thumb_path(path))
  end

  def sample_path(path)
    File.join(@sample_dir, path.sub(File.extname(path), ".#{@format}"))
  end

  def sample_fullpath(path)
    File.join(@storage_dir, sample_path(path))
  end

  def local_encoding(path)
    if @arranged_file_encoding
      Iconv.iconv(@arranged_file_encoding, 'UTF-8', path).first
    else
      path
    end
  end
end
