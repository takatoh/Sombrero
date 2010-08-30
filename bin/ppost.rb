#!ruby
#
# ppost.rb - Post photos to sombrero.
#

require File.dirname(__FILE__) + "/../boot"
require 'pcrawler'
require 'photo_registrar'
require 'optparse'


SCRIPT_VERSION = "0.3.1"


def err_exit(msg)
  $stderr.print msg
  exit
end

def register_photo(photo)
  begin
    puts photo["file"]
    unless @options[:dryrun]
      p = @ragistrar.post(photo["file"], { :url => photo["url"],
                                           :page_url => photo["page_url"],
                                           :tags     => photo["tags"] } )
      puts "  => Accepted: #{p.width}x#{p.height} (#{p.md5})"
    end
  rescue PhotoRegistrar::Rejection => err
    puts "  => Rejected: #{err.message}"
  end
end


@options = { :dryrun => false,
           }

psr = OptionParser.new
psr.banner =<<EOB
Post photos to Sombrero.
Usage: #{psr.program_name} [option] FILE
EOB
psr.on('-u', '--url=URL', %q[photo URL.]){|v| @options[:url] = v}
psr.on('-p', '--page-url=URL', %q[page URL.]){|v| @options[:page_url] = v}
psr.on('-i', '--input=YAML', %q[input from YAML file.]){|v| @options[:input] = v}
psr.on('--source-dir=DIR', %q[read file from DIR.]){|v| @options[:source_dir] = v}
psr.on('-f', '--force', %q[force to register.]){|v| @options[:force] = true}
psr.on('-t', '--tags=TAGS', %q[set tags.]){|v| @options[:tags] = v}
psr.on('--dry-run', %q[not register photos.]){@options[:dryrun] = true}
psr.on_tail('-v', '--version', %q[show version.]){puts "#{psr.program_name} v#{SCRIPT_VERSION}"; exit}
psr.on_tail('-h', '--help', %q[show this message.]){puts "#{psr}"; exit}
begin
  psr.parse!
rescue OptionParser::InvalidOption => err
  err_exit(err.message)
end


@ragistrar = PhotoRegistrar.new(:keep => true, :force => @options[:force])
sources = if @options[:input]
  src = YAML.load_file(@options[:input])
  if @options[:source_dir]
    src.map{|p| p.update("file" => File.join(@options[:source_dir], p["file"]))}
  end
  src
else
  [ { "file" => ARGV.shift,
      "url" => @options[:url],
      "page_url" => @options[:page_url],
      "tags" => @options[:tags] } ]
end

puts "Register to database."
puts ""
sources.each do |src|
  register_photo(src)
end
