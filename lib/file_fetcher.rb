#
#  File fetcher
#


require "http"
require "pathname"

require "image_types"


class FileFetcher

  include ImageTypes

  class NotImage < StandardError; end
  class FetchError < StandardError; end

  def self.fetch(url, opts = {})
    h = HTTP.head(url)
    case h.status
    when 200     # OK
      if opts[:ignore_media_type] || IMAGE_CONTENT_TYPES.member?(h["Content-Type"])
        c = HTTP.get(url)
        filename = Pathname.new("./tmp") + chop_query(File.basename(url))
        # X (Twitter)
        if url.start_with?("https://pbs.twimg.com/")
          ext = /format=([a-z]+)/.match(url)[1]
          filename = filename.sub_ext("." + ext)
        end
        # Bluesky
        if url.start_with?("https://cdn.bsky.app/img/")
          ext = /@([a-z]+)\z/.match(url)[1]
          filename = filename.sub_ext("." + ext)
        end
        File.open(filename, "wb"){|f| f.write(c.body)}
        filename
      else
        raise NotImage.new("Content-Type: #{h["Content-Type"]}")
      end
    when 302     # Moved Temporarily
      location = h["Location"].first
      fetch(location, opts)
    else
      raise FetchError.new("Status: #{h.status}: #{url}")
    end
  end

end   # of class FileFetcher


  def chop_query(url)
    url.sub(/[\?\:].+\z/, "")
  end
