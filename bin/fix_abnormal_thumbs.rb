require "./boot"
require "model/photo"
require "optparse"


def main
  options = parse_options

  photos = Photo.order_by("id").where(Sequel.like(:thumbnail_path, "thumbs/.j%")).all

  count = 0
  photos.each do |photo|
    md5 = photo[:md5]
    filename = md5 + ".jpg"
    subdir = "#{md5[0, 2]}/#{md5[2, 2]}"

    thumb_path = ["thumbs", subdir, filename].join("/")
    puts "ID:  #{photo[:id]}"
    puts "        #{photo[:thumbnail_path]}"
    if options[:dry_run]
      puts "    =>  #{thumb_path}"
    else
      puts "copied  #{thumb_path}"
    end

    sample_path = ["samples", subdir, filename].join("/")
    puts "        #{photo[:sample_path]}"
    if options[:dry_run]
      puts "    =>  #{sample_path}"
    else
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
