module Rack::Sprockets

  class NotSprocketsRequest < RuntimeError; end
  class SprocketsAssetNotFound < RuntimeError; end
  class NoResponseStatus < RuntimeError; end

  module Helpers

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

    # Asset digest fingerprint.
    # ie. "foo-0aa2105d29558f3eb790d411d7d8fb66.js"
    #   => "0aa2105d29558f3eb790d411d7d8fb66"
    def path_info_fingerprint
      unescaped_path_info[/-([0-9a-f]{7,40})\.[^.]+$/, 1]
    end

    def unescaped_path_info
      @unescaped_path_info ||= unescape(path_info.to_s)
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
