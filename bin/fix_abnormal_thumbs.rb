require "./boot"
require "model/photo"
require "fileutils"
require "optparse"


def main
  options = parse_options

  photos = Photo.order_by("id").where(Sequel.like(:thumbnail_path, "thumbs/.j%")).all

  count = 0
  photos.each do |photo|
    md5 = photo[:md5]
    filename = md5 + ".jpg"
    subdir = "#{md5[0, 2]}/#{md5[2, 2]}"

    puts "ID:  #{photo[:id]}"
    thumb_path = ["thumbs", subdir, filename].join("/")
    src_thumb_path = photo[:thumbnail_path]
    puts "        #{src_thumb_path}"
    if options[:dry_run]
      puts "    =>  #{thumb_path}"
    else
      src = [SOMBRERO_CONFIG["storage"], src_thumb_path].join("/")
      dest = [SOMBRERO_CONFIG["storage"], thumb_path].join("/")
      FileUtils.mkdir_p(File.dirname(dest))
      FileUtils.cp(src, dest, :preserve => true)
      photo[:thumbnail_path] = thumb_path
      photo.save
      puts "copied  #{thumb_path}"
    end

    sample_path = ["samples", subdir, filename].join("/")
    src_sample_path = photo[:sample_path]
    puts "        #{src_sample_path}"
    if options[:dry_run]
      puts "    =>  #{sample_path}"
    else
      src = [SOMBRERO_CONFIG["storage"], src_sample_path].join("/")
      dest = [SOMBRERO_CONFIG["storage"], sample_path].join("/")
      FileUtils.mkdir_p(File.basename(dest))
      FileUtils.cp(src, dest, :preserve => true)
      photo[:sample_path] = sample_path
      photo.save
      puts "copied  #{sample_path}"
    end

    count += 1
  end

  puts "\n\n#{count} thubmnails and samples are fixed."
end


def parse_options
  options = {}

  parser = OptionParser.new
  parser.on("-d", "--dry-run", "Dry running"){|v| options[:dry_run] = true }
  parser.on_tail("-h", "--help", "Show this message"){ puts parser.help; exit(0) }
  parser.parse!

  options
end



main
