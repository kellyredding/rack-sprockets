class MockOptions
  include Rack::Sprockets::Options
  
  def initialize
    @env = nil
    initialize_options
  end
end

