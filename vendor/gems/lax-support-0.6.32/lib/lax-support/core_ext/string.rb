# Extend core String classs to add some useful UTF-8 support
class String
  # Get number of characters (instead of bytes) for a given UTF8 string
  #   puts '德州扑克'.length_utf8  # 4
  def length_utf8
      count = 0
      scan(/./mu) { count += 1 }
      count
   end
   alias :size_utf8 :length_utf8
end

