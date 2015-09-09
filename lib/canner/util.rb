class Util

  # ensures whatever is passed in comes out an array of symbols
  class << self
    def prepare(str)
      Array(str).flatten.map(&:to_sym)
    end
  end
end
