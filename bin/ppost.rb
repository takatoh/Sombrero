#!ruby
#
# ppost.rb - Post photos to sombrero.
#

require "./boot"
require 'photo_registrar'
require 'plogger'
require 'optparse'


SCRIPT_VERSION = "0.4.0"


at_exit { @log.close if @log }


class FileNotExist < StandardError; end


def err_exit(msg)
  $stderr.print msg
  exit
end

def register_photo(photo)
  begin
    @log.puts photo["file"]
    raise FileNotExist.new("File not exist") unless File.exist?(photo["file"])
    unless @options[:dryrun]
      p = @registrar.post(photo["file"], { :url      => photo["url"],
                                           :page_url => photo["page_url"],
                                           :tags     => photo["tags"] } )
      @log.puts "  => Accepted: #{p.width}x#{p.height} (#{p.md5})"
      @counter[:accepted] += 1
    end
  rescue PhotoRegistrar::Rejection => err
    @log.puts "  => Rejected: #{err.message}"
    @counter[:rejected] += 1
    if @options[:add_tags]
      tag_num = @registrar.add_tags(photo["file"], photo["tags"])
      @log.puts "  => Add tags: #{tag_num}"
    end
  end
end

IMAGES = %w( .jpg .jpeg .png .bmp .gif )

def search_dir(dir, options = {})
  dir = Pathname.new(dir)
  sbr_info = dir + "sbrinfo"
  opts = if sbr_info.exist?
    info = {}
    YAML.load_file(sbr_info).each{|k, v| info[k.intern] = v }
    options.dup.update(info)
  else
    options.dup
  end
  files = dir.children.select{|f| f.file? && IMAGES.include?(f.extname.downcase)}.map do |f|
    { "file"     => f.to_s,
      "url"      => opts[:url],
      "page_url" => opts[:page_url],
      "tags"     => opts[:tags] }
  end
  dirs = dir.children.select{|d| d.directory?}.map{|d| search_dir(d, opts)}.flatten
  files.concat(dirs)
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
psr.on('-a', '--add-tags', %q[add tags even if photo allready exist.]){|v| @options[:add_tags] = true}
psr.on('-f', '--force', %q[force to register.]){|v| @options[:force] = true}
psr.on('-i', '--input=YAML', %q[input from YAML file.]){|v| @options[:input] = v}
psr.on('--source-dir=DIR', %q[read file from DIR. use with --input option.]){|v|
  @options[:source_dir] = v
}
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


@registrar = PhotoRegistrar.new(:keep => true, :force => @options[:force])
@log = @options[:log] ? PLogger.new(@options[:log]) : $stdout
sources = if @options[:input]
  src = YAML.load_file(@options[:input])
  if @options[:source_dir]
    src.map{|p| p.update("file" => File.join(@options[:source_dir], p["file"]))}
  end
  src
else
  files = if ARGV.size == 1 && File.directory?(ARGV[0])
    search_dir(ARGV.shift, @options)
  else
    ARGV.map do |file|
      { "file"     => file,
        "url"      => @options[:url],
        "page_url" => @options[:page_url],
        "tags"     => @options[:tags] }
    end
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
