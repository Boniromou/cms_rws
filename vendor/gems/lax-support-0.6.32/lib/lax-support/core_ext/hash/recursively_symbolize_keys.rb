class Hash

  def recursively_symbolize_keys
    inject({}) do |hash, (key, value)|
      hash[key.to_sym] = value.is_a?(Hash) ? value.recursively_symbolize_keys : value
      hash
    end
  end  

  def recursively_symbolize_keys!
    replace(inject({}) do |hash, (key, value)|
      hash[key.to_sym] = value.is_a?(Hash) ? value.recursively_symbolize_keys! : value
      hash
    end)
  end

  def recursively_stringify_keys
    inject({}) do |hash, (key, value)|
      hash[key.to_s] = value.is_a?(Hash) ? value.recursively_stringify_keys : value
      hash
    end
  end

  def recursively_stringify_keys!
    replace(inject({}) do |hash, (key, value)|
      hash[key.to_s] = value.is_a?(Hash) ? value.recursively_stringify_keys! : value
      hash
    end)
  end

end
