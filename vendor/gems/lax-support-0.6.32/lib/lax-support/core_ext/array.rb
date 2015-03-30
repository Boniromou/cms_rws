dir, base = *File.split(__FILE__)
base = base.chomp('.rb')
Dir[File.join(dir, base, '*')].sort.each do |lib|
  require "lax-support/core_ext/#{base}/#{File.basename(lib)}"
end
