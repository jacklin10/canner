class Util

  # ensures whatever is passed in comes out an array of symbols
  class << self
    def prepare(str)
      symbolize(arrayify(str))
    end

    # ensures the array elements are symbols
    def symbolize(strings)
      strings.map{|s| s.to_sym}
    end

    # ensure given roles are in the form of an array
    def arrayify(roles)
      Array.wrap(roles).flatten
    end

  end

end
