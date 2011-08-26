require 'assert'
require "test/app_helper"
require 'test/fixtures/sinatra/app'

module Rack::Sprockets

  class SinatraTests < Assert::Context

    def app
      @app ||= SinatraApp
    end

    def default_value(name)
      Base.defaults["#{Rack::Sprockets::Options::RACK_ENV_NS}.#{name}"]
    end

    desc "A Sinatra app using Rack::Sprockets"

  end

  class ValidSinatraTest < SinatraTests
    desc "requesting valid JavaScript"
    setup do
      app.use Rack::Sprockets,
        :root => file_path('test','fixtures','sinatra')

      @compiled = File.read(file_path('test','fixtures','sinatra','app','javascripts', 'app_compiled.js'))
      @response = visit "/javascripts/app.js"
    end

    should_respond_with_compiled_js
  end

  class InvalidSinatraTest < SinatraTests
    desc "requesting valid nested JavaScript"
    setup do
      app.use Rack::Sprockets,
        :root => file_path('test','fixtures','sinatra')

      @compiled = File.read(file_path('test','fixtures','sinatra','app','javascripts', 'nested', 'thing_compiled.js'))
      @response = visit "/javascripts/nested/thing.js"
    end

    should_respond_with_compiled_js
  end

end
