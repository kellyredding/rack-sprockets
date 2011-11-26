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
    should have_instance_methods :set!, :asset, :to_rack

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
      subject.send :set_not_modified
    end

    should "set the status code to 304" do
      assert_equal 304, subject.status
    end

    should "set not modified when fingerprint matches HTTP_IF_NONE_MATCH" do
      digest = "c24985518b1f067a69b350dedef6c2f2"
      req = sprockets_request(@base.config, "GET", "/javascripts/alert_one-#{digest}.js")
      req.env['HTTP_IF_NONE_MATCH'] = "\"#{digest}\""
      res = sprockets_response(@base.config, req)

      assert_nothing_raised { res.set! }
      assert_equal 304, res.status
    end
  end

  class JsExceptionTests < ResponseTests
    desc "when js exception"
    setup do
      begin
        raise "test js error"
      rescue Exception => err
        subject.send :set_js_exception, err
      end
    end

    should "set the status code to 200 and return a body that throws error info" do
      assert_equal 200, subject.status
      assert_match /^throw Error/, subject.body
      assert_includes "test js error", subject.body
      assert_equal "application/javascript", subject.headers["Content-Type"]
      assert_equal Rack::Utils.bytesize(subject.body).to_s, subject.headers["Content-Length"]
    end

    should "set js exception response if processing errors" do
      req = sprockets_request(@base.config, "GET", "/javascripts/errors.js")
      res = sprockets_response(@base.config, req)

      assert_nothing_raised { res.set! }
      assert_match /^throw Error/, res.body
    end

  end

  class CssExceptionTests < ResponseTests
    desc "when css exception"
    setup do
      begin
        raise "test css error"
      rescue Exception => err
        subject.send :set_css_exception, err
      end
    end

    should "set the status code to 200 and return a body with error info" do
      assert_equal 200, subject.status
      assert_match /^\s+html/, subject.body
      assert_includes "test css error", subject.body
      assert_match /^text\/css/, subject.headers["Content-Type"]
      assert_equal Rack::Utils.bytesize(subject.body).to_s, subject.headers["Content-Length"]
    end

    should "set css exception response if processing errors" do
      req = sprockets_request(@base.config, "GET", "/javascripts/errors.css")
      res = sprockets_response(@base.config, req)

      assert_nothing_raised { res.set! }
      assert_match /^\s+html/, res.body
    end

  end

  class OkTests < ResponseTests
    desc "when ok"
    setup do
      subject.send :set_ok
      puts subject.body.inspect
    end

    should "set the status code to 200 and return asset source in body" do
      assert_equal 201, subject.status
      assert_match /^var one_message/, subject.body
      assert_equal "application/javascript", subject.headers["Content-Type"]
      assert_equal Rack::Utils.bytesize(subject.body).to_s, subject.headers["Content-Length"]
    end

    should "set js exception response if processing errors" do
      req = sprockets_request(@base.config, "GET", "/javascripts/app_compiled.js")
      res = sprockets_response(@base.config, req)

      assert_nothing_raised { res.set! }
      assert_match /^var one_message/, subject.body
    end

  end

end
