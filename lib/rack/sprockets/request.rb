require 'rack/request'

module Rack::Sprockets

  # Provides access to the HTTP request.
  # Request objects respond to everything defined by Rack::Request
  # as well as some additional convenience methods defined here

  class Request < Rack::Request

    # The HTTP request method. This is the standard implementation of this
    # method but is respecified here due to libraries that attempt to modify
    # the behavior to respect POST tunnel method specifiers. We always want
    # the real request method.
    def request_method
      @env['REQUEST_METHOD']
    end

    def path_info
      @env['PATH_INFO']
    end

    def query_string
      @env["QUERY_STRING"]
    end

    def http_accept
      @env['HTTP_ACCEPT']
    end

    def http_if_modified
      @env['HTTP_IF_MODIFIED_SINCE']
    end

    def http_etag
      @env['HTTP_IF_NONE_MATCH']
    end

    def initialize(config, env)
      @config = config
      super(env)
    end

    # Determine if the request is for a non-cached existing Sprockets asset
    # This will be called on every request so speed is an issue
    # => first check if the request is GET for :hosted_at sprockets media (fast)
    # => otherwise, check for a sprockets asset that matches the request (slow)
    # TODO: test
    def for_asset?
      get? &&          # GET for :hosted_at sprockets media? (fast, check first)
      !path_info_forbidden? &&
      hosted_at? &&
      sprockets_media? &&
      asset            # an asset for the request? (slowest, check last)
    end

    # The Sprockets Asset being requested
    def asset
      @asset ||= @config.sprockets.find_asset(asset_path, :bundle => !query_body_only?)
    end

    # take the request, config, and sprockets env info
    # build an asset lookup path
    def asset_path
      @asset_path ||= unescaped_path_info.
                      sub("-#{asset_fingerprint}", '').
                      sub(/^#{@config.hosted_at}/, '').
                      sub(/^\//, '')
    end

    # Asset digest fingerprint.
    # ie. "foo-0aa2105d29558f3eb790d411d7d8fb66.js"
    #   => "0aa2105d29558f3eb790d411d7d8fb66"
    def asset_fingerprint
      unescaped_path_info[/-([0-9a-f]{7,40})\.[^.]+$/, 1]
    end

    def unescaped_path_info
      @unescaped_path_info ||= unescape(path_info.to_s)
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

    private

    # URI.unescape is deprecated on 1.9. We need to use URI::Parser
    # if its available.
    if defined? URI::DEFAULT_PARSER
      def unescape(str)
        URI::DEFAULT_PARSER.unescape(str).tap do |str|
          (e = Encoding.default_internal) ? str.force_encoding(e) : str
        end
      end
    else
      def unescape(str)
        URI.unescape(str)
      end
    end

    # Test if `?body=1` or `body=true` query param is set
    def query_body_only?
      query_string.to_s =~ /body=(1|t)/
    end

  end
end
