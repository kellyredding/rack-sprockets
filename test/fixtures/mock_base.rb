require 'rack/sprockets/config'

class MockBase
  include Rack::Sprockets::Config

  attr_reader :sprockets_env

  def initialize(configs={})
    self.config.apply(configs)
    self.config.sprockets = configured_sprockets_env
  end

end

