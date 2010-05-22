#!ruby
#
# Rubygem `Hpricot' is required.
# You can install the gem:
#
# <tt>gem install hpricot</tt>
#

require File.dirname(__FILE__) + "/../boot"
require 'pcrawler'
require 'registrar'


SCRIPT_VERSION = "0.2.0"


def err_exit(msg)
  $stderr.print msg
  exit
end

def register_photo(image)
  begin
    puts image[:image_url]
    unless @options[:dryrun]
      photo = @ragistrar.clip({:url => image[:image_url], :page_url => image[:page_url]})
      puts "  => Accepted: #{photo.width}x#{photo.height} (#{photo.md5})"
    end
  rescue FileFetcher::NotImage => err
    puts "  => Not image: #{err.message}"
  rescue PhotoRegistrar::Rejection => err
    puts "  => Rejected: #{err.message}"
  end
end

def conv_opt(opt)
  { :dryrun            => opt["dry-run"],
    :rec               => opt["recursive"],
    :verbose           => opt["verbose"],
    :ignore_media_type => opt["ignore-media-type"],
    :link_only         => opt["link-only"],
    :embed_only        => opt["embed_only"]
  }
end


@options = { :dryrun => false,
          }

psr = OptionParser.new
psr.banner =<<EOB
Pick out hyper-links in specified page.
Usage: #{psr.program_name} [option] URL
EOB
psr.on('-d', '--dry-run', %q[not register photos.]){@options[:dryrun] = true}
psr.on('-r', '--recursive=N', %q[recursive crawl.]){|v| @options[:rec] = v.to_i}
psr.on('-i', '--input=YAML', %q[input url and options from YAML file.]){|v| @options[:input] = v}
psr.on('-V', '--verbose', %q[verbose mode.]){@options[:verbose] = true}
psr.on('--ignore-media-type', %q[ignore media-type.]){@options[:ignore_media_type] = true}
psr.on('--link-only', %q[register linked photo only.]){@options[:link_only] = true}
psr.on('--embed-only', %q[register embeded photo only.]){@options[:embed_only] = true}
psr.on_tail('-v', '--version', %q[show version.]){puts "#{psr.program_name} ver.#{SCRIPT_VERSION}"; exit}
psr.on_tail('-h', '--help', %q[show this message.]){puts "#{psr}"; exit}
begin
  psr.parse!
rescue OptionParser::InvalidOption => err
  err_exit(err.message)
end


sources = if @options[:input]
  YAML.load_file(@options[:input])
else
  [ {"url" => ARGV.shift, "options" => @options} ]
end
sources.each do |src|
  url = src["url"]
  opt = @options[:input] ? conv_opt(src["options"] || {}) : src["options"]
  puts ""
  puts "Start crawling: #{url}"
  puts "  at #{Time.now.to_s}"
  crawler = PCrawler.new(url, opt)
  crawler.crawl

  @ragistrar = PhotoRegistrar.new(opt)
  print "\n"
  puts "Register to database."
  unless opt[:link_only]
    puts "--- Embeded images:"
    crawler.embeded_images.each do |i|
      register_photo(i)
    end
  end
  unless opt[:embed_only]
    puts "--- Linked images:"
    crawler.linked_images.each do |i|
      register_photo(i)
    end
  end
end
