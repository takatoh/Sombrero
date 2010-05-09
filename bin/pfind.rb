#!ruby
#
# pfind - Find photos in specified directory on local file system.
#

require 'pfinder'
require 'registrar'
require 'optparse'


SCRIPT_VERSION = "0.0.0"


def err_exit(msg)
  $stderr.print msg
  exit
end


psr = OptionParser.new
psr.banner =<<EOB
Find photos in specified directory on local file system.

Usage: #{psr.program_name} [option] URL
EOB
psr.on_tail('-v', '--version', %q[show version.]){puts "#{psr.program_name} ver.#{SCRIPT_VERSION}"; exit}
psr.on_tail('-h', '--help', %q[show this message.]){puts "#{psr}"; exit}
begin
  psr.parse!
rescue OptionParser::InvalidOption => err
  err_exit(err.message)
end

dir = File.expand_path(ARGV.shift)
photos = PFinder.new(dir).find

registrar = PhotoRegistrar.new
photos.each do |photo|
  puts photo[:image_url]
  registrar.post({:url => photo[:image_url], :page_url => photo[:page_url]})
end

