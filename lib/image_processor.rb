#
# Image processor
#
require "vips"


class ImageProcessor

  # Get the dimensions of an image
  def self.get_image_size(filename)
    image = Vips::Image.new_from_file(filename.to_s)
    [image.width, image.height]
  end
  
  # Resize an image (downsize only)
  def self.downsize_to_limit(filename, thumb_width, thumb_height, thumb_filename)
    thumb = Vips::Image.thumbnail(
        filename.to_s,
        thumb_width,
        height: thumb_height,
        size: :down
    )
    thumb.write_to_file(thumb_filename.to_s)
    [thumb.width, thumb.height]
  end

end   # of class ImageProcessor
