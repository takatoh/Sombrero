#!ruby
#
# ppost.rb - Post photos to sombrero.
#

require File.dirname(__FILE__) + "/../boot"
require 'pcrawler'
require 'photo_registrar'
require 'plogger'
require 'optparse'


SCRIPT_VERSION = "0.3.2"


at_exit { @log.close if @log }

def err_exit(msg)
  $stderr.print msg
  exit
end

def register_photo(photo)
  begin
    @log.puts photo["file"]
    unless @options[:dryrun]
      p = @ragistrar.post(photo["file"], { :url      => photo["url"],
                                           :page_url => photo["page_url"],
                                           :tags     => photo["tags"] } )
      @log.puts "  => Accepted: #{p.width}x#{p.height} (#{p.md5})"
      @counter[:accepted] += 1
    end
  rescue PhotoRegistrar::Rejection => err
    @log.puts "  => Rejected: #{err.message}"
    @counter[:rejected] += 1
  end
end


@options = {
  :dryrun => false,
}

psr = OptionParser.new
psr.banner =<<EOB
Post photos to Sombrero.
Usage: #{psr.program_name} [option] <file>
EOB
psr.on('-u', '--url=URL', %q[photo URL.]){|v| @options[:url] = v}
psr.on('-p', '--page-url=URL', %q[page URL.]){|v| @options[:page_url] = v}
psr.on('-t', '--tags=TAGS', %q[set tags.]){|v| @options[:tags] = v}
psr.on('-f', '--force', %q[force to register.]){|v| @options[:force] = true}
<<<<<<< HEAD
psr.on('--source-dir=DIR', %q[read file from DIR.]){|v| @options[:source_dir] = v}
psr.on('-i', '--input=YAML', %q[input from YAML file.]){|v| @options[:input] = v}
=======
psr.on('-i', '--input=YAML', %q[input from YAML file.]){|v| @options[:input] = v}
psr.on('--source-dir=DIR', %q[read file from DIR. use with --input option.]){|v|
  @options[:source_dir] = v
}
>>>>>>> master
psr.on('-l', '--log[=FILE]', %q[log to FILE. default is 'ppost.log'.]){|v|
  @options[:log] = v || "ppost.log"
}
psr.on('--dry-run', %q[not register photos.]){@options[:dryrun] = true}
psr.on_tail('-v', '--version', %q[show version.]){
  puts "#{psr.program_name} v#{SCRIPT_VERSION}"; exit
}
psr.on_tail('-h', '--help', %q[show this message.]){puts "#{psr}"; exit}
begin
  psr.parse!
rescue OptionParser::InvalidOption => err
  err_exit(err.message)
end


@ragistrar = PhotoRegistrar.new(:keep => true, :force => @options[:force])
@log = @options[:log] ? PLogger.new(@options[:log]) : $stdout
sources = if @options[:input]
  src = YAML.load_file(@options[:input])
  if @options[:source_dir]
    src.map{|p| p.update("file" => File.join(@options[:source_dir], p["file"]))}
  end
  src
else
  files = if ARGV.size == 1 && File.directory?(ARGV[0])
    Dir.glob("#{ARGV.shift}/**/*").select{|f| File.file?(f)}.sort
  else
    ARGV
  end
  files.map do |file|
    { "file"     => file,
      "url"      => @options[:url],
      "page_url" => @options[:page_url],
      "tags"     => @options[:tags] }
  end
end

@counter = {:accepted => 0, :rejected => 0, :error => 0}
@log.puts "Register to database."
@log.puts ""
sources.each do |src|
  begin
    register_photo(src)
  rescue => err
    @log.puts "  => ERROR(SKIP): #{err.message}"
    @counter[:error] += 1
  end
end
@log.puts ""
@log.puts "Accepted: #{@counter[:accepted]}"
@log.puts "Rejected: #{@counter[:rejected]}"
@log.puts "Error:    #{@counter[:error]}"
@log.puts "TOTAL:    #{@counter.to_a.inject(0){|a,b| a + b[1]}}"
