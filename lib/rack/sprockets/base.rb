require 'rack/sprockets/config'
require 'rack/sprockets/request'
require 'rack/sprockets/response'

module Rack::Sprockets
  class Base

    # Store off the app reference and apply any configs
    def initialize(app, configs={})
      @app = app

      # setup and validate the configs
      @config = Rack::Sprockets::Config.new(configs || {})
      yield @config if block_given?
      @config.validate!
    end

    # The Rack call interface. The receiver acts as a prototype and runs
    # each request in a clone object unless the +rack.run_once+ variable is
    # set in the environment.
    def call(env)
      if env['rack.run_once']
        call! env
      else
        clone.call! env
      end
    end

    # The real Rack call interface.
    # if a Sprockets resource is being requested and is found, this is an endpoint:
    # otherwise, call on up to the app as normal
    def call!(env)
      begin
        request = Request.new(@config, env.dup.freeze)
        request.validate!
        response = Response.new(@config, env.dup.freeze, request)
        response.set!
      rescue NotSprocketsRequest, SprocketsAssetNotFound => err
        # call up middleware stack - this is not a sprockets request
        @app.call(env)
      else
        # Mark session as "skipped" so no `Set-Cookie` header is set
        env['rack.session.options'] ||= {}
        env['rack.session.options'][:defer] = true
        env['rack.session.options'][:skip] = true

        # return the rack response tuple
        response.to_rack
      end
    end

  end
end
