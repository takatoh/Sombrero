require "./boot"
require "model/photo"


def main
  photos = Photo.order_by("id").where(Sequel.like(:thumbnail_path, "thumbs/.j%")).all

  count = 0
  photos.each do |photo|
    md5 = photo[:md5]

    thumb_filename = md5 + ".jpg"
    thumb_path = ["thumbs", md5[0, 2], md5[2, 2], thumb_filename].join("/")
    puts "#{photo[:id]}: #{photo[:thumbnail_path]}"
    puts "    =>  #{thumb_path}"

    sample_filename = md5 + ".jpg"
    sample_path = ["samples", md5[0, 2], md5[2, 2], sample_filename].join("/")
    puts "        #{photo[:sample_path]}"
    puts "    =>  #{sample_path}"

    count += 1
  end

#  puts "#{count} thubmnails and samples are fixed."
end



main
