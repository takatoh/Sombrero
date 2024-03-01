#
# Radom string generator
#


class RandomString

  def initialize(pool = nil)
    @pool = pool || "abcdefghijklmnopqrstuvwxyz0123456789"
  end

  def generate(length)
    s = ""
    length.times do
      s << @pool[rand(@pool.length)]
    end
    s
  end

end   # of class RandomString
