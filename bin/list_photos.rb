require "./boot"
require "model/photo"
require "model/post"
require "optparse"


def main
  default_options = {
    max: 100
  }
  options = parse_options(default_options)

  photos = Photo.dataset.order_by("id").limit(options[:max])

  photos.each do |photo|
    puts "#{photo[:id]}:"
    puts "  size:        #{photo[:width]}x#{photo[:height]}"
    puts "  file size:   #{photo[:filesize]}"
    puts "  md5:         #{photo[:md5]}"
    puts "  sha256:      #{photo[:sha256]}"
    puts "  path:        #{photo[:path]}"
    puts "  sample path: #{photo[:sample_path]}"
    puts "  thumb path:  #{photo[:thumbnail_path]}"
    puts "  posts:"
    photo.posts.each do |post|
      puts "    [#{post.id}]  #{post.url}"
    end
  end
end


def parse_options(default_options)
  options = default_options

  parser = OptionParser.new
  parser.on("-m", "--max=MAX", "Maximum count for phots"){|v| options[:max] = v.to_i }
  parser.on_tail("-h", "--help", "Show this message"){ puts parser.help; exit(0) }
  parser.parse!

  options
end



main
