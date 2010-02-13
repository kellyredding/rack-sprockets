require 'rack'
require 'rack/sprockets/config'
#require 'rack/sprockets/base'
#require 'rack/sprockets/options'
#require 'rack/sprockets/request'
#require 'rack/sprockets/response'
#require 'rack/sprockets/source'

# === Usage
#
# Create with default configs:
#   require 'rack/sprockets'
#   Rack::Sprockets.new(app, :compress => true)
#
# Within a rackup file (or with Rack::Builder):
#   require 'rack/sprockets'
#
#   use Rack::Sprockets,
#     :source   => 'app/scripts'
#     :compress => true
#
#   run app

module Rack::Sprockets
  MIME_TYPE = "text/javascript"
  @@config = Config.new
  
  class << self
    
    # Configuration accessors for Rack::Sprockets
    # (see config.rb for details)
    def configure
      yield @@config if block_given?
    end
    def config
      @@config
    end
    def config=(value)
      @@config = value
    end
    
  end

  # Create a new Rack::Sprockets middleware component 
  # => the +options+ Hash can be used to specify default option values
  # => a block can given as an alternate method for setting option values (see example above)
  # => (see Rack::Sprockets::Options for possible key/values)
  def self.new(app, options={}, &block)
    Base.new(app, options, &block)
  end
  
end
