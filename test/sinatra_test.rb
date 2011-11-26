require 'assert'
require "test/app_helper"
require 'test/fixtures/sinatra/app'

module Rack::Sprockets

  class SinatraTests < Assert::Context

    def app
      @app ||= SinatraApp
    end

    desc "A Sinatra app using Rack::Sprockets"

  end

  class ValidSinatraTest < SinatraTests
    desc "requesting valid JavaScript"
    setup do

      @compiled = File.read(file_path('test','fixtures','sinatra','app','javascripts', 'app_compiled.js'))
      @response = visit "/app.js"
    end

    should "respond appropriately" do
      assert_equal 200, @response.status
      assert @response.headers["Content-Type"].include?("application/javascript")
      assert_equal @compiled.gsub(/\s+/, ''), @response.body.strip.gsub(/\s+/, '')
    end

  end

  class NestedSinatraTest < SinatraTests
    desc "requesting valid nested JavaScript"
    setup do
      app.use Rack::Sprockets,
        :root => file_path('test','fixtures','sinatra'),
        :load_path => ["test/fixtures/sinatra/app/javascripts"]

      @compiled = File.read(file_path('test','fixtures','sinatra','app','javascripts', 'nested', 'thing_compiled.js'))
      @response = visit "/nested/thing.js"
    end

    should "respond appropriately" do
      assert_equal 200, @response.status
      assert @response.headers["Content-Type"].include?("application/javascript")
      assert_equal @compiled.gsub(/\s+/, ''), @response.body.strip.gsub(/\s+/, '')
    end

  end

end
