#!ruby
#


require File.dirname(__FILE__) + "/../boot"
require 'pcrawler'
require 'registrar'


SCRIPT_VERSION = "0.0.0"


def err_exit(msg)
  $stderr.print msg
  exit
end

def register_photo(photo)
  begin
    puts photo["file"]
    unless @options[:dryrun]
      p = @ragistrar.post(photo["file"], {:url => photo["url"], :page_url => photo["page_url"]})
      puts "  => Accepted: #{p.width}x#{p.height} (#{p.md5})"
    end
  rescue PhotoRegistrar::Rejection => err
    puts "  => Rejected: #{err.message}"
  end
end


@options = { :dryrun  => false,
             :verbose => false
           }

psr = OptionParser.new
psr.banner =<<EOB
Pick out hyper-links in specified page.
Usage: #{psr.program_name} [option] URL
EOB
#psr.on('-i', '--input=YAML', %q[input from YAML file.]){|v| @options[:input] = v}
#psr.on('-d', '--dry-run', %q[not register photos.]){@options[:dryrun] = true}
#psr.on('-V', '--verbose', %q[verbose mode.]){@options[:verbose] = true}
psr.on_tail('-v', '--version', %q[show version.]){puts "#{psr.program_name} v#{SCRIPT_VERSION}"; exit}
psr.on_tail('-h', '--help', %q[show this message.]){puts "#{psr}"; exit}
begin
  psr.parse!
rescue OptionParser::InvalidOption => err
  err_exit(err.message)
end


sources = if @options[:input]
  YAML.load_file(@options[:input])
else
  [ {"file" => ARGV.shift, "url" => nil, "page_url" => nil} ]
end
sources.each do |src|
  @ragistrar = PhotoRegistrar.new(:keep => true)
  print "\n"
  puts "Register to database."
  register_photo(src)
end
