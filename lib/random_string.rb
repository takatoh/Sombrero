#
# Radom string generator
#


class RandomString

  def initialize(pool = nil)
    @pool = pool || ("a".."z").to_a + ("0".."9").to_a
  end

  def generate(length)
    s = ""
    length.times do
      s << @pool[rand(@pool.length)]
    end
    s
  end

end   # of class RandomString
