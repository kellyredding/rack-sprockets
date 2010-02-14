require "#{File.dirname(__FILE__)}/../test_helper"
require "test_app_helper"
require 'fixtures/sinatra/app'

class SinatraTest < Test::Unit::TestCase

  def app
    @app ||= SinatraApp
  end
  def default_value(name)
    Rack::Sprockets::Base.defaults["#{Rack::Sprockets::Options::RACK_ENV_NS}.#{name}"]
  end

  context "A Sinatra app using Rack::Sprockets" do    
    should "fail when no options are set" do
      assert_raise ArgumentError do
        app.use Rack::Sprockets
        visit "/"
      end
    end
    
    should "fail when no :root option is set" do
      assert_raise ArgumentError do
        app.use Rack::Sprockets, :compress => false
        visit "/"
      end
    end
    
    should "fail when :root option does not exist" do
      assert_raise ArgumentError do
        app.use Rack::Sprockets,
          :root => file_path('test','fixtures','wtf')
        
        visit "/"
      end
    end
    
    should "fail when :source option does not exist" do
      assert_raise ArgumentError do
        app.use Rack::Sprockets,
          :root   => file_path('test','fixtures','sinatra'),
          :source => 'wtf'
        
        visit "/"
      end
    end
    
    context "requesting valid JavaScript" do
      setup do
        app.use Rack::Sprockets,
          :root => file_path('test','fixtures','sinatra')
        
        @compiled = File.read(file_path('test','fixtures','sinatra','app','javascripts', 'app_compiled.js'))
        @response = visit "/javascripts/app.js"
      end

      should_respond_with_compiled_js
    end
  end

end