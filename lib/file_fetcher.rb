#
#  File fetcher
#


require 'http'

require 'image_types'


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
        filename = File.basename(url)
        { :filename => filename, :body => c.body }
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
