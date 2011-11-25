require 'rack/sprockets/helpers'

module Rack::Sprockets

  # Given some config and a sprockets asset, generate Rack::Response
  # parameters based on the asset.
  # => call to_rack to build standard rack response parameters
  class Response
    include Helpers

    # Rack response tuple accessors.
    attr_accessor :status, :headers, :body

    def initialize(config, env, request)
      raise ArgumentError, "no request provided" if request.nil?

      @config = config
      @env = env
      @request = request

      @status = nil
      @headers = {}
      @body = ""
    end

    def validate!
      begin
        # Check request headers `HTTP_IF_NONE_MATCH` against the asset digest
        if etag_match?
          # Return a 304 Not Modified
          build_not_modified_response
        else
          # Return a 200 with the asset contents
          build_ok_response
        end
      rescue Exception => e
        case @config.sprockets.content_type_of(@request.asset_path)
        when "application/javascript"
          # Re-throw JavaScript asset exceptions to the browser
          build_js_exception_response(e)
        when "text/css"
          # Display CSS asset exceptions in the browser
          build_css_exception_response(e)
        else
          # re-raise on up
          raise
        end
      end
    end

    # The Sprockets Asset being requested
    # * returns nil if no asset is found
    # * raises exceptions if errors compiling asset
    def asset
      @asset ||= @config.sprockets.find_asset(@request.asset_path, :bundle => !query_body_only?)
    end

    def to_rack
      [self.status, self.headers, [self.body]]
    end

    protected

    # a 304 Not Modified response
    def build_not_modified_response
      self.status = 304
    end

    # a 200 OK response
    def build_ok_response
      self.status = 200
      self.body = self.asset
      set_headers!
    end

    # throw JavaScript exception to the browser
    def build_js_exception_response(exception)
    end

    # show CSS exception in the browser
    def build_css_exception_response(exception)
    end

    def set_headers!
      # Set content type and length headers
      headers["Content-Type"]   = asset_content_type
      headers["Content-Length"] = body_content_length.to_s

      # Set caching headers
      headers["Cache-Control"]  = "public"
      headers["Last-Modified"]  = asset_mtime_httpdate
      headers["ETag"]           = asset_etag

      if path_info_fingerprint
        # If the request url contains a fingerprint, set a long
        # expires on the response
        headers["Cache-Control"] << ", max-age=31536000"
      else
        # Otherwise set `must-revalidate` since the asset could be modified.
        headers["Cache-Control"] << ", must-revalidate"
      end
    end

    private

    def asset_content_type
      self.asset.content_type
    end

    # Calculate appropriate content_length
    def body_content_length
      self.body.respond_to?(:bytesize) ? self.body.bytesize : self.body.size
    end

    # Compare the requests `HTTP_IF_MODIFIED_SINCE` against the
    # assets mtime
    def not_modified?
      http_if_modified == asset_mtime_httpdate
    end

    def asset_mtime_httpdate
      self.asset.mtime.httpdate
    end

    # Compare the requests `HTTP_IF_NONE_MATCH` against the assets digest
    def etag_match?
      http_etag == asset_etag
    end

    def asset_etag
      %("#{self.asset.digest}")
    end

  end
end
