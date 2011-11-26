require 'assert'

require 'rack/test'
require 'webrat'

require 'rack/sprockets'

class Assert::Context
  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers

  Webrat.configure do |config|
    config.mode = :rack
  end

end
