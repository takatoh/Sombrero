#
#  File fetcher
#


require "httpclient"

require "image_types"


class FileFetcher

  include ImageTypes

  class NotImage < StandardError; end
  class FetchError < StandardError; end

  def self.fetch(url, opts = {})
    client = HTTPClient.new
    h = client.head(url)
    case h.status
    when 200     # OK
      if opts[:ignore_media_type] || IMAGE_CONTENT_TYPES.member?(h.contenttype)
        c = client.get(url)
        filename = File.basename(url)
        { :filename => filename, :body => c.content }
      else
        raise NotImage.new("Content-Type: #{h.contenttype}")
      end
    when 302     # Moved Temporarily
      location = h.header["Location"].first
      fetch(location, opts)
    else
      raise FetchError.new("Status: #{h.status}: #{url}")
    end
  end

end   # of class FileFetcher
