#
#  PhotoStorage
#


require "fileutils"
require "pathname"
require "uri"

require "random_string"


class PhotoStorage

  THUMBNAIL_GEOMETRY = "150x150"
  SAMPLE_WIDTH       = 600
  SAMPLE_HEIGHT      = 800
  FILE_NAME_LETTERS  = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a


  def initialize(base_dir, randomize = false)
    @storage_dir   = Pathname.new(base_dir).expand_path
    @photo_dir     = "photos"
    @thumbnail_dir = "thumbs"
    @sample_dir    = "samples"
    @format        = "jpg"
    @randomize     = randomize
  end


  def store(content, filename)
    if @randomize
      filename, fullpath = generate_random_filename_and_fullpath(filename)
      while check_file_exist?(fullpath)
        filename, fullpath = generate_random_filename_and_fullpath(filename)
      end
    else
      fullpath = photo_fullpath(filename)
    end
    unless File.exist?(fullpath)
      FileUtils.mkdir_p(fullpath.parent)
      File.open(fullpath, "wb"){|f| f.write(content)}
    end
    name = filename.sub(File.extname(filename), ".#{@format}")
    thumb_path = make_thumbnail(fullpath, {:name => name})
    sample_path = make_sample(fullpath, {:name => name})
    [ photo_path(filename), thumb_path, sample_path ]
  end


  def put_ext(path, extname)
    fullpath = @storage_dir + path
    fullpath_new = fullpath.sub_ext("." + extname)
    FileUtils.mv(fullpath, fullpath_new)
    path + "." + extname
  end


  private

  def make_thumbnail(photopath, opts)
    thumbpath = thumb_fullpath(opts[:name])
    return thumb_path(opts[:name]) if File.exist?(thumbpath)
    FileUtils.mkdir_p(thumbpath.parent)
    system("convert -thumbnail #{THUMBNAIL_GEOMETRY} -flatten #{photopath} #{thumbpath}")
    thumb_path(opts[:name])
  end


  def make_sample(photopath, opts = {})
    samplepath = sample_fullpath(opts[:name])
    return sample_path(opts[:name]) if File.exist?(samplepath)
    FileUtils.mkdir_p(samplepath.parent)
    width = `identify -format %[width] #{photopath}`.to_i
    height = `identify -format %[height] #{photopath}`.to_i
    if width > SAMPLE_WIDTH or height > SAMPLE_HEIGHT
      system("convert -scale #{SAMPLE_WIDTH}x#{SAMPLE_HEIGHT} -flatten #{photopath} #{samplepath}")
    else
      FileUtils.cp(photopath, samplepath)
    end
    sample_path(opts[:name])
  end


  def photo_path(filename)
    build_path(@photo_dir, filename)
  end


  def photo_fullpath(filename)
    @storage_dir + photo_path(filename)
  end


  def thumb_path(filename)
    build_path(@thumbnail_dir, filename)
  end


  def thumb_fullpath(filename)
    @storage_dir + thumb_path(filename)
  end


  def sample_path(filename)
    build_path(@sample_dir, filename)
  end


  def sample_fullpath(filename)
    @storage_dir + sample_path(filename)
  end


  def build_path(dir, filename)
    File.join(dir, filename.slice(0,2).downcase, filename.slice(2,2).downcase, filename)
  end


  def generate_random_filename_and_fullpath(filename)
    random_string = RandomString.new(FILE_NAME_LETTERS)
    filename = random_string.generate(12) + File.extname(filename)
    fullpath = photo_fullpath(filename)
    [filename, fullpath]
  end


  def check_file_exist?(fullpath)
    filename = fullpath.basename.to_s.downcase
    parent = fullpath.parent
    if parent.exist?
      files = fullpath.parent.children.select{|c| c.file? }.map{|c| c.basename.to_s.downcase }
      files.include?(filename)
    else
      false
    end
  end

end   # of class PhotoStorage
