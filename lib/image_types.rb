#
#  Image types
#

module ImageTypes

  IMAGE_TYPES = [ "jpeg", "jpg", "png", "bmp", "gif" ]
  IMAGE_CONTENT_TYPES = [ "image/jpeg", "image/png", "image/bmp", "image/gif" ]


  def included_type?(file)
    ext = File.extname(file).tr(".", "")
    IMAGE_TYPES.include?(ext)
  end

end   # of module ImageTypes

