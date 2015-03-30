class Array #:nodoc:

  def to_str
    v = ""
    each do |e|
      if e.respond_to?(:to_str)
        v << e.to_str
      else
        v << e.to_s
      end
    end
    v
  end

end
