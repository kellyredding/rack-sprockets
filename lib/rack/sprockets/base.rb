require 'rack/sprockets/options'
require 'rack/sprockets/request'
require 'rack/sprockets/response'

module Rack::Sprockets
  class Base
    include Rack::Sprockets::Options

    def initialize(app, options={})
      @app = app
      initialize_options options
      yield self if block_given?
      validate_options
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
    # if Sprockets JS is being requested, this is an endpoint:
    # => generate the compiled javascripts
    # => respond appropriately
    # Otherwise, call on up to the app as normal
    def call!(env)
      @default_options.each { |k,v| env[k] ||= v }
      @env = env
      
      if (@request = Request.new(@env.dup.freeze)).for_sprockets?
        Response.new(@env.dup.freeze, @request.source.to_js).to_rack
      else
        @app.call(env)
      end
    end
    
    private
    
    def validate_options
      # ensure a root path is specified and does exists
      unless options.has_key?(option_name(:root)) and !options(:root).nil?
        raise(ArgumentError, "no :root option set")
      end
      unless File.exists?(options(:root))
        raise(ArgumentError, "the :root path ('#{options(:root)}') does not exist") 
      end

      set :root, File.expand_path(options(:root))

      # ensure a source path is specified and does exists
      unless options.has_key?(option_name(:source)) and !options(:source).nil?
        raise(ArgumentError, "no :source option set")
      end
      source_path = File.join(options(:root), options(:source))
      unless File.exists?(source_path)
        raise(ArgumentError, "the :source path ('#{source_path}') does not exist") 
      end
    end

  end
end