require 'rubygems'
require 'bundler'
Bundler.setup

require 'sinatra'
Bundler.require(:default)

# use the rack-sprockets middleware with default options:
# => http://github.com/kelredd/rack-sprockets --> README --> "Available Options" for details
use Rack::Sprockets

# configure rack-sprockets with custom configuration settings
# => http://github.com/kelredd/rack-sprockets --> README --> "Available Configurations" for details
Rack::Sprockets.configure do |config|
  config.cache = true
  config.compress = :yui
end