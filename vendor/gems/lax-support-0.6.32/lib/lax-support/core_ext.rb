# Dynamically load all core extension libraries.

Dir[File.dirname(__FILE__) + "/core_ext/*.rb"].sort.each do |path|
  filename = File.basename(path, '.rb')
  require "lax-support/core_ext/#{filename}"
end
