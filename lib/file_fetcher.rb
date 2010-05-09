#
#  File fetcher
#

require 'open-uri'
require 'rubygems'
require 'httpclient'

require 'boot'
require 'image_types'


class FileFetcher

  include ImageTypes

  class NotImage < StandardError; end

  def self.fetch(url, opts = {})
    client = HTTPClient.new
    h = client.head(url)
    if opts[:ignore_media_type] || IMAGE_CONTENT_TYPES.member?(h.contenttype)
      c = client.get(url)
      body = c.content
      filename = File.basename(url)
      { :filename => filename, :body => body }
    else
      raise NotImage.new("Content-Type: #{h.contenttype}")
    end
  rescue => err
    raise NotImage.new
  end

end   # of class FileFetcher
