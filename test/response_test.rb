require 'assert'

require 'rack/sprockets/response'
require 'rack/sprockets/request'
require 'test/fixtures/mock_base'

module Rack::Sprockets

  class ResponseTests < Assert::Context
    desc 'Rack::Sprockets::Response'
    setup do
      @base = MockBase.new({
        :load_path => ["test/fixtures/sinatra/app/javascripts"],
        :hosted_at => "/javascripts",
        :mime_types => [['application/javascript', '.js']]
      })
      @js = File.read(file_path('test','fixtures','sinatra','app','javascripts', 'app_compiled.js'))
      @request = sprockets_request(@base.config, "GET", "/javascripts/app.js")
      @response = sprockets_response(@base.config, @request)
    end
    subject { @response }

    should have_accessors :status, :headers, :body
    should have_instance_methods :validate!, :asset, :to_rack

    should "have some rack attributes" do
      [ :request_method,
        :path_info,
        :query_string,
        :http_accept,
        :http_if_modified,
        :http_etag,
      ].each do |a|
        assert_respond_to a, @request, "request does not respond to #{a.inspect}"
      end
    end

    should "complain if building with nil request" do
      assert_raises ArgumentError do
        sprockets_response(@base.config, nil)
      end
    end

    should "default its status, headers, body" do
      assert_nil subject.status
      assert_equal Hash.new, subject.headers
      assert_equal "", subject.body
    end

    should "return a rack response tuple" do
      assert_equal [subject.status, subject.headers, [subject.body]], subject.to_rack
    end

    should "know its sprockets asset" do
      req = sprockets_request(@base.config, "GET", "/javascripts/alert_one.js")
      res = sprockets_response(@base.config, req)
      assert res.asset
      assert_kind_of Sprockets::BundledAsset, res.asset

      req = sprockets_request(@base.config, "GET", "/javascripts/alert_one.js", "body=1")
      res = sprockets_response(@base.config, req)
      assert res.asset
      assert_kind_of Sprockets::ProcessedAsset, res.asset

      req = sprockets_request(@base.config, "GET", "/javascripts/does_not_exist.js")
      res = sprockets_response(@base.config, req)
      assert_not res.asset
    end

    should "complain if trying to build an asset that has compile errors" do
      req = sprockets_request(@base.config, "GET", "/javascripts/errors.js")
      res = sprockets_response(@base.config, req)

      assert_raises Sprockets::FileNotFound do
        res.asset
      end
    end

  end

  class NotModifiedTests < ResponseTests
    desc "when not modified"
    setup do
      subject.send :build_not_modified_response
      digest = "c24985518b1f067a69b350dedef6c2f2"
      @req = sprockets_request(@base.config, "GET", "/javascripts/alert_one-#{digest}.js")
      @req.env['HTTP_IF_NONE_MATCH'] = "\"#{digest}\""
      @res = sprockets_response(@base.config, @req)
    end

    should "set the status code to 304" do
      assert_equal 304, subject.status
    end

    should "validate not modified when fingerprint matches HTTP_IF_NONE_MATCH" do
      assert_nothing_raised do
        @res.validate!
      end
      assert_equal 304, @res.status
    end
  end

  class OkTests < ResponseTests
    # should "set it's status to '#{Rack::Utils::HTTP_STATUS_CODES[200]}'" do
    #   assert_equal 200, @response.status
    # end

    # should "set it's Content-Type to '#{Rack::Sprockets::MIME_TYPE}'" do
    #   assert_equal Rack::Sprockets::MIME_TYPE, @response.content_type, 'the content_type accessor is incorrect'
    #   assert_equal Rack::Sprockets::MIME_TYPE, @response.headers['Content-Type'], 'the Content-Type header is incorrect'
    # end

    # should "set it's Content-Length appropriately" do
    #   assert_equal Rack::Sprockets::Response.content_length(@js), @response.content_length, 'the content_length accessor is incorrect'
    #   assert_equal Rack::Sprockets::Response.content_length(@js), @response.headers['Content-Length'].to_i
    # end
  end

  class JsExceptionTests < ResponseTests
  end

  class CssExceptionTests < ResponseTests
  end

end
