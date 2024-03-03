require "./boot"
require "model/photo"

ds = Photo.order_by("id")
photos = ds.all

photos.each do |photo|
  puts "#{photo[:id]}:"
  puts "  size:        #{photo[:width]}x#{photo[:height]}"
  puts "  file size:   #{photo[:filesize]}"
  puts "  md5:         #{photo[:md5]}"
  puts "  sha256:      #{photo[:sha256]}"
  puts "  path:        #{photo[:path]}"
  puts "  sample path: #{photo[:sample_path]}"
  puts "  thumb path:  #{photo[:thumbnail_path]}"
end

