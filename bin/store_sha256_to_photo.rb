require "./boot"
require "model/photo"
require "digest"
require "optparse"


def main
  options = parse_options

  photos = Photo.order_by("id").all

  count = 0
  photos.each do |photo|
    next unless photo.sha256.nil?

    file = File.join(SOMBRERO_CONFIG["storage"], photo.path)
    content = File.open(file, "rb"){|f| f.read }
    sha256 = Digest::SHA256.hexdigest(content)

    puts "ID:  #{photo[:id]}"
    if options[:dry_run]
      puts "  SHA256 = #{sha256}"
    else
      photo[:sha256] = sha256
      photo.save
      puts "  SHA256 stored = #{sha256}"
    end

    count += 1
    break if count == options[:max_count]
  end

  puts "\n\n#{count} photos are fixed."
end


def parse_options
  options = {}

  parser = OptionParser.new
  parser.on("-d", "--dry-run", "Dry running"){|v| options[:dry_run] = true }
  parser.on("-m", "--max", "Maximum count to store"){|v| options[:max_count] = v.to_i }
  parser.on_tail("-h", "--help", "Show this message"){ puts parser.help; exit(0) }
  parser.parse!

  options
end



main
