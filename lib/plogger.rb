#
# PLogger
#


class PLogger

  def initialize(logfile)
    @logfile = File.open(logfile, "w")
  end

  def puts(str)
    $stdout.puts(str)
    @logfile.puts(str)
  end

  def close
    @logfile.close
  end

end   # of PLogger
