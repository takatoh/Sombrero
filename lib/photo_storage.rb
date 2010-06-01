#
#  PhotoStorage
#

require 'rubygems'
require 'rmagick'
require 'fileutils'
require 'pathname'
require 'uri'
require 'digest/md5'


class PhotoStorage

  def initialize(base_dir)
    @storage_dir   = Pathname.new(base_dir).expand_path
    @photo_dir     = "photos"
    @thumbnail_dir = "thumbs"
    @sample_dir    = "samples"
    @format = "jpg"
  end


  def store(content, filename)
    fullpath = photo_fullpath(filename)
    dir = fullpath.parent
    unless File.exist?(dir)
      FileUtils.mkdir_p(dir)
    end
    File.open(fullpath, "wb") do |f|
      f.write(content)
    end
    name = filename.sub(File.extname(filename), ".#{@format}")
    thumb_path = make_thumbnail(fullpath, {:name => name})
    sample_path = make_sample(fullpath, {:name => name})
    [ photo_path(filename), thumb_path, sample_path ]
  end


  def make_thumbnail(photopath, opts = {})
    thumbpath = thumb_fullpath(opts[:name])
    return thumb_path(opts[:name]) if File.exist?(thumbpath) and !opts[:force]
    unless File.exist?(thumbpath.parent)
      FileUtils.mkdir_p(thumbpath.parent)
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
    unless File.exist?(samplepath.parent)
      FileUtils.mkdir_p(samplepath.parent)
    end
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

  def photo_path(filename)
    File.join(@photo_dir, filename.slice(0,2), filename.slice(2,2), filename)
  end

  def photo_fullpath(filename)
    @storage_dir + photo_path(filename)
  end

  def thumb_path(filename)
    File.join(@thumbnail_dir, filename.slice(0,2), filename.slice(2,2), filename)
  end

  def thumb_fullpath(filename)
    @storage_dir + thumb_path(filename)
  end

  def sample_path(filename)
    File.join(@sample_dir, filename.slice(0,2), filename.slice(2,2), filename)
  end

  def sample_fullpath(filename)
    @storage_dir + sample_path(filename)
  end

end   # of class PhotoStorage

