module LaxSupport

  module VERSION #:nodoc:
    MAJOR    = 0
    MINOR    = 6 
    TINY     = 32

    STRING   = [MAJOR, MINOR, TINY].join('.')

    CODENAME = 'Everest'
  end

  NAME    = 'lax-support'.freeze
  RELEASE  = "#{NAME} #{VERSION::STRING} codename #{VERSION::CODENAME}".freeze

  def self.win?
    RUBY_PLATFORM =~ /mswin/
  end

  def self.linux?
    RUBY_PLATFORM =~ /linux/
  end

  def self.ruby_18?
    RUBY_VERSION =~ /^1\.8/
  end

  def self.ruby_19?
    RUBY_VERSION =~ /^1\.9/
  end

end

