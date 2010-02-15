module RackSprockets
  module Version
    
    MAJOR = 1
    MINOR = 0
    TINY  = 2
    
    def self.to_s # :nodoc:
      [MAJOR, MINOR, TINY].join('.')
    end
    
  end
end