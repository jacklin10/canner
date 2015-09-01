class Util

  # ensures whatever is passed in comes out an array of symbols
  class << self
    def prepare(str)
      symbolize(arrayify(str).flatten)
    end

    # ensures the array elements are symbols
    def symbolize(strings)
      strings.map{|s| s.to_sym}
    end

    # ensure given roles are in the form of an array
    def arrayify(roles)
      if roles.nil?
        []
      elsif roles.respond_to?(:to_ary)
        roles.to_ary || [roles]
      else
        [roles]
      end
    end
  end
end
