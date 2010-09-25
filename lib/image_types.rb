#
#  Image types
#

module ImageTypes

  IMAGE_TYPES = [ "jpeg", "jpg", "png", "bmp", "gif" ]
  IMAGE_CONTENT_TYPES = [ "image/jpeg", "image/png", "image/bmp", "image/gif" ]


  def included_type?(file)
    file = file.sub(/\?.+\z/, "")
    ext = File.extname(file).tr(".", "")
    IMAGE_TYPES.include?(ext)
  end

end   # of module ImageTypes

