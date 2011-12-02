require 'rack/sprockets/helpers'
require 'rack/utils'

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

    def set!
      begin
        # Check request headers `HTTP_IF_NONE_MATCH` against the asset digest
        if etag_match?
          # Return a 304 Not Modified
          set_not_modified
        else
          # Return a 200 with the asset contents
          set_ok
        end
      rescue SprocketsAssetNotFound
        raise
      rescue Exception => e
        case @config.sprockets_env.content_type_of(@request.asset_path)
        when "application/javascript"
          # Re-throw JavaScript asset exceptions to the browser
          set_js_exception(e)
        when "text/css"
          # Display CSS asset exceptions in the browser
          set_css_exception(e)
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
      @asset ||= find_asset
    end

    def to_rack
      if self.status.nil?
        raise NoResponseStatus, "no response status code.  has #set! method been called?"
      end
      [self.status, self.headers, [self.body]]
    end

    protected

    # a 304 Not Modified response
    def set_not_modified
      self.status = 304
    end

    # throw JavaScript exception to the browser
    def set_js_exception(exception)
      self.status = 200

      err = "#{exception.class.name}: #{exception.message}"
      self.body = "throw Error(#{err.inspect});"

      self.headers["Content-Type"]   = "application/javascript"
      self.headers["Content-Length"] = body_content_length.to_s
    end

    # show CSS exception in the browser
    def set_css_exception(exception)
      self.status = 200

      err = "\n#{exception.class.name}: #{exception.message}"
      backtrace = "\n  #{exception.backtrace.first}"
      self.body = <<-CSS
        html {
          padding: 18px 36px;
        }

        head {
          display: block;
        }

        body {
          margin: 0;
          padding: 0;
        }

        body > * {
          display: none !important;
        }

        head:after, body:before, body:after {
          display: block !important;
        }

        head:after {
          font-family: sans-serif;
          font-size: large;
          font-weight: bold;
          content: "Error compiling CSS asset";
        }

        body:before, body:after {
          font-family: monospace;
          white-space: pre-wrap;
        }

        body:before {
          font-weight: bold;
          content: "#{escape_css_content(err)}";
        }

        body:after {
          content: "#{escape_css_content(backtrace)}";
        }
      CSS

      self.headers["Content-Type"]   = "text/css;charset=utf-8"
      self.headers["Content-Length"] = body_content_length.to_s
    end

    # a 200 OK response
    def set_ok
      self.status = 200

      self.body = self.asset.source

      self.headers["Content-Type"]   = asset_content_type
      self.headers["Content-Length"] = body_content_length.to_s

      self.headers["Cache-Control"]  = "public"
      self.headers["Last-Modified"]  = asset_mtime_httpdate
      self.headers["ETag"]           = asset_etag

      if path_info_fingerprint
        # If the request url contains a fingerprint, set a long
        # expires on the response
        self.headers["Cache-Control"] << ", max-age=31536000"
      else
        # Otherwise set `must-revalidate` since the asset could be modified.
        self.headers["Cache-Control"] << ", must-revalidate"
      end
    end

    private

    def find_asset
      @config.sprockets_env.find_asset(@request.asset_path, {
        :bundle => !query_body_only?
      }).tap { |asset| raise_asset_not_found(@request.asset_path) if asset.nil? }
    end

    def raise_asset_not_found(asset_path)
      raise SprocketsAssetNotFound, "no asset '#{@request.asset_path}'"
    end


    def asset_content_type
      self.asset.content_type
    end

    # Calculate appropriate content_length
    def body_content_length
      Rack::Utils.bytesize(self.body)
    end

    # Escape special characters for use inside a CSS content("...") string
    def escape_css_content(content)
      content.
        gsub('\\', '\\\\005c ').
        gsub("\n", '\\\\000a ').
        gsub('"',  '\\\\0022 ').
        gsub('/',  '\\\\002f ')
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
