require 'rack/response'
require 'rack/utils'

module Rack::Sprockets

  # Given some generated js, mimicks a Rack::Response
  # => call to_rack to build standard rack response parameters
  class Response
    include Rack::Sprockets::Options
    include Rack::Response::Helpers

    # Rack response tuple accessors.
    attr_accessor :status, :headers, :body
    
    class << self

      # Calculate appropriate content_length
      def content_length(body)
        if body.respond_to?(:bytesize)
          body.bytesize
        else
          body.size
        end
      end
      
    end

    # Create a Response instance given the env
    # and some generated js.
    def initialize(env, js)
      @env = env
      @body = js
      @status = 200 # OK
      @headers = Rack::Utils::HeaderHash.new

      headers["Content-Type"] = Rack::Sprockets::MIME_TYPE
      headers["Content-Length"] = self.class.content_length(body).to_s
    end
    
    def to_rack
      [status, headers.to_hash, body]
    end

  end
end