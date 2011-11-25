require 'rack/request'
require 'rack/sprockets/helpers'

module Rack::Sprockets

  # Provides access to the HTTP request.
  # Request objects respond to everything defined by Rack::Request
  # as well as some additional convenience methods defined here

  # Given a configuration (with configured Sprockets env), determine if
  # this request if for a Sprockets asset or not

  class Request < Rack::Request
    include Helpers

    def initialize(config, env)
      @config = config
      super(env)
    end

    # take the request, config, and sprockets env info
    # build an asset lookup path
    def asset_path
      @asset_path ||= unescaped_path_info.
                      sub("-#{path_info_fingerprint}", '').
                      sub(/^#{@config.hosted_at}/, '').
                      sub(/^\//, '')
    end

    def validate!
      raise NotSprocketsRequest if !valid?
    end

    # Determine if the request is valid.  This will be called on every request
    # so speed is an issue.  A valid request is one that is:
    # * a GET request (fastest)
    # * not forbidden
    # * is hosted
    # * for sprockets media (slowest, checked last)
    def valid?
      get? &&
      !path_info_forbidden? &&
      hosted_at? &&
      sprockets_media?
    end

    # is this request for sprockets media, based on the config
    def sprockets_media?
      @config.mime_types.for_format?(File.extname(path_info)) ||
      @config.mime_types.accept?(http_accept) ||
      @config.mime_types.for_media_type?(media_type)
    end

    # is this request hosted by the middleware, based on its config
    def hosted_at?
      path_info =~ /^#{@config.hosted_at}/
    end

    # Prevent access to files elsewhere on the file system
    # ie. http://example.org/assets/../../../etc/passwd
    def path_info_forbidden?
      path_info =~ /\.\.\//
    end

  end
end
