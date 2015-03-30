class Hash

  def to_str
    v = ""
    each do |key, value|
      if key.respond_to?(:to_str)
        v << key.to_str
      else
        v << key.to_s
      end
      if value.respond_to?(:to_str)
        v << value.to_str
      else
        v << value.to_s
      end
    end
    v
  end

end
