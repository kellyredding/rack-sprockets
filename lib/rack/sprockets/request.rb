require 'rack/request'
require 'rack/sprockets'
require 'rack/sprockets/options'
require 'rack/sprockets/source'

module Rack::Sprockets

  # Provides access to the HTTP request.
  # Request objects respond to everything defined by Rack::Request
  # as well as some additional convenience methods defined here

  class Request < Rack::Request
    include Rack::Sprockets::Options
    
    JS_PATH_FORMATS = ['.js']

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
    
    def http_accept
      @env['HTTP_ACCEPT']
    end
    
    def path_resource_name
      File.basename(path_info, path_resource_format)
    end
    
    def path_resource_format
      File.extname(path_info)
    end

    # The Rack::Sprockets::Source that the request is for
    def source
      @source ||= begin
        cache = if Rack::Sprockets.config.cache?
          File.join(options(:root), options(:public), options(:hosted_at))
        else
          nil
        end
        source_opts = {
          :folder    => File.join(options(:root), options(:source)),
          :cache     => cache,
          :compress  => Rack::Sprockets.config.compress,
          :secretary => {
            :root         => options(:root),
            :load_path    => options(:load_path),
            :expand_paths => options(:expand_paths)
          }
        }
        Source.new(path_resource_name, source_opts)
      end
    end

    def for_js?
      (http_accept && http_accept.include?(Rack::Sprockets::MIME_TYPE)) ||
      (media_type  && media_type.include?(Rack::Sprockets::MIME_TYPE )) ||
      JS_PATH_FORMATS.include?(path_resource_format)
    end

    # Determine if the request is for an existing Sprockets source file
    # This will be called on every request so speed is an issue
    # => first check if the request is a GET on a js resource (fast)
    # => then check for sprockets source files that match the request (slow)
    def for_sprockets?
      get? && for_js? && !source.files.empty?
    end
    
  end
end
