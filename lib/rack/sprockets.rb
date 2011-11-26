require 'rack'
require 'rack/sprockets/base'

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

  # Create a new Rack::Sprockets middleware component
  # => the +options+ Hash can be used to specify default option values
  # => (see Rack::Sprockets::Options for possible key/values)
  def self.new(app, options={}, &block)
    Base.new(app, options, &block)
  end

end
