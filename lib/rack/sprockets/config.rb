module Rack::Sprockets
  
  # Handles configuration for Rack::Sprockets
  # Available config settings:
  # :cache
  #   whether to cache the compilation output to
  #   a corresponding static file. Also determines
  #   what value config#combinations(:key) returns
  # :compress
  #   Whether or not to apply compression to the
  #   concatenation output - uses YUI Compressor
  #   if available or will remove extraneous
  #   whitespace if not.
  
  class Config
    
    ATTRIBUTES = [:cache, :compress]
    attr_accessor *ATTRIBUTES
    
    DEFAULTS = {
      :cache    => false,
      :compress => false
    }

    def initialize(settings={})
      ATTRIBUTES.each do |a|
        instance_variable_set("@#{a}", settings[a] || DEFAULTS[a])
      end
    end
    
    def cache?
      !!@cache
    end
    
    def compress?
      !!@compress
    end
    
  end
end