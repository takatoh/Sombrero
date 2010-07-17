#
#  PCrawler
#

require 'net/http'
require 'uri'
require 'rubygems'
require 'nokogiri'
require 'image_types'


class PCrawler

  attr_reader :embeded_images, :linked_images, :linked_pages, :background_images

  def initialize(url, options)
    @url = url
    proxy = ENV['http_proxy'] || ENV['http-proxy']
    if proxy
      prxy = URI.parse(proxy)
      @proxy_host = prxy.host
      @proxy_port = prxy.port
    else
      @proxy_host = nil
      @proxy_port = nil
    end
    @options = options
    @embeded_images = []
    @linked_images = []
    @linked_pages = []
    @background_images = []
  end

  def crawl
    $stderr.puts "Start crawling: #{@url}\n" if @options[:verbose]
    begin
      g = ContentGetter.new(@url, @proxy_host, @proxy_port, @options)
      g.get
      @embeded_images.concat(g.pick_img)
      @linked_images.concat(g.pick_aimg)
      frames = g.pick_frame
      frames.each do |frm|
        c = PCrawler.new(frm, @options)
        c.crawl
        @embeded_images.concat(c.embeded_images)
        @linked_images.concat(c.linked_images)
      end
      @background_images = g.pick_bg_images if @options[:include_bg_image]
      linked_pages = g.pick_linked_pages
      if @options[:rec].nil? || @options[:rec] <= 1
        @linked_pages.concat(linked_pages).sort.uniq
      else
        opts2 = @options.dup
        opts2[:rec] = @options[:rec] - 1
        linked_pages.each do |lp|
          next if @linked_pages.member?(lp)
          @linked_pages << lp
          crawl(lp, opts2)
        end
      end
      self
    rescue ContentGetter::UnwelcomeResponse => err
    rescue => err
      $stderr.puts err.message
    end
  end


  ## inner class

  class ContentGetter

    include ImageTypes

    class UnwelcomeResponse < StandardError; end

    def initialize(url, proxy_host, proxy_port, options)
      @url = url
      u = URI.parse(@url)
      @host = u.host
      @port = u.port
      @path = u.path
      @options = options
      @http = Net::HTTP.new(@host, @port, proxy_host, proxy_port)
      port = @http.port == 80 ? "" : ":" + @http.port.to_s
      @url_base = "http://#{@http.address}#{port}#{dirname(@path)}/"
    end

    def get
      $stderr.puts "Getting: #{@url}" if @options[:verbose]
      response = @http.start {|http| http.get(@path) }
      raise UnwelcomeResponse.new("Unwelcome response: code=#{response.code}; url=#{@url}") unless response.code == "200"
      @content = response.body
      @root = Nokogiri::HTML(@content).root
    end

    def pick_img
      img = @root.search("img").map{|i| i["src"]} + @root.search("img").map{|i| i["SRC"]}
      img = img.compact.select do |l|
        included_type?(l)
      end.map{|l| url_clean(full_url(l)) }.sort.uniq.map do |i|
        { :image_url => i, :page_url => @url }
      end
      if @options[:verbose]
        $stderr.puts "  Embeded images:"
        img.each {|i| $stderr.puts "  #{i[:image_url]}"}
      end
      img || []
    end

    def pick_aimg
      img = @root.search("a").map{|i| i["href"]} + @root.search("a").map{|i| i["HREF"]}
      img = img.compact.select do |l|
        included_type?(l)
      end.map do |l|
        url_clean(full_url(l))
      end.sort.uniq.map do |i|
        { :image_url => i, :page_url => @url }
      end
      if @options[:verbose]
        $stderr.puts "  Linked images:"
        img.each {|i| $stderr.puts "  #{i[:image_url]}"}
      end
      img || []
    end

    def pick_linked_pages
      links = @root.search("a").map{|i| i["href"]}
      links = links.select do |l|
        if l.nil?
          false
        else
          !included_type?(l)
        end
      end.map do |l|
        url_clean(full_url(l).sub(/#.+\z/, ""))
      end.sort.uniq.select do |l|
        u = URI.parse(l)
        @host == u.host
      end
      if @options[:verbose]
        $stderr.puts "  Linked pages:"
        links.each {|i| $stderr.puts "  #{i}"}
      end
      links || []
    end

    def pick_frame
      frames = @root.search("frame").map{|i| i["src"]} + @root.search("frame").map{|i| i["SRC"]}
      frames = frames.compact.map do |fr|
        url_clean(full_url(fr).sub(/#.+\z/, ""))
      end.sort.uniq.select do |fr|
        u = URI.parse(fr)
        @host == u.host
      end
      if @options[:verbose]
        $stderr.puts "  Frames:"
        frames.each {|fr| $stderr.puts "  #{fr}"}
      end
      frames || []
    end

    def pick_bg_images
      bg_images = @root.search("//*/@background").map do |a|
        { :image_url => url_clean(full_url(a.value)), :page_url => @url }
      end
      if @options[:verbose]
        $stderr.puts "  Background images:"
        bg_images.each{|bg| $stderr.puts "  #{bg[:image_url]}"}
      end
      bg_images || []
    end

    private

    def url_clean(url)
      url.gsub(%r{[^/]+/\.\./}, "").gsub("/./", "/")
    end

    def full_url(url)
      unless /\A(https?|ftp|mailto):/ =~ url then @url_base + url else url end
    end

    def dirname(path)
      /\/[^\/]*\z/.match(path).pre_match
    end
  end   # of ContentGetter

end   # of PCrawler

