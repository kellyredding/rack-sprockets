require 'rack/sprockets/config'

class MockBase

  attr_reader :config

  def initialize(configs={})
    @config = Rack::Sprockets::Config.new(configs)
  end

end

