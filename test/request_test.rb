require 'assert'

require 'rack/sprockets/request'
require 'test/fixtures/mock_base'

module Rack::Sprockets

  class RequestTests < Assert::Context
    desc 'Rack::Sprockets::Request'
    setup do
      # @defaults = env_defaults
      @base = MockBase.new({
        :load_path => ["test/fixtures/sinatra/app/javascripts"],
        :hosted_at => "/javascripts",
        :mime_types => [['application/javascript', '.js']]
      })
      @request = sprockets_request(@base.config, "GET", "/foo.js")
    end
    subject { @request }

    should have_instance_methods :asset_path
    should have_instance_methods :hosted_at?, :sprockets_media?, :path_info_forbidden?
    should have_instance_methods :valid?, :validate!

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

    should "know if it is forbidden" do
      req = sprockets_request(@base.config, "GET", "/lala.js")
      assert_not req.path_info_forbidden?

      req = sprockets_request(@base.config, "GET", "/../lala.css")
      assert req.path_info_forbidden?
    end

    should "know if it is hosted" do
      req = sprockets_request(@base.config, "GET", "/javascripts/lala.js")
      assert req.hosted_at?

      req = sprockets_request(@base.config, "GET", "/lala.js")
      assert_not req.hosted_at?

      req = sprockets_request(@base.config, "GET", "/stylesheets/lala.css")
      assert_not req.hosted_at?
    end

    should "know if it is for sprockets media" do
      req = sprockets_request(@base.config, "GET", "/lala.js")
      assert req.sprockets_media?

      req = sprockets_request(@base.config, "GET", "/lala.css")
      assert_not req.sprockets_media?
    end

    should "know its unescaped path info" do
      req = sprockets_request(@base.config, "GET", "/lala.js")
      assert_equal "/lala.js", req.unescaped_path_info

      req = sprockets_request(@base.config, "GET", "/lala%20lala.js")
      assert_equal "/lala lala.js", req.unescaped_path_info
    end

    should "know its path info fingerprint" do
      req = sprockets_request(@base.config, "GET", "/lala.js")
      assert_equal nil, req.path_info_fingerprint

      req = sprockets_request(@base.config, "GET", "/lala-3462346246.js")
      assert_equal "3462346246", req.path_info_fingerprint

      req = sprockets_request(@base.config, "GET", "/lala-lala.js")
      assert_equal nil, req.path_info_fingerprint

      req = sprockets_request(@base.config, "GET", "/lala-0aa2105d29558f3eb790d411d7d8fb66.js")
      assert_equal "0aa2105d29558f3eb790d411d7d8fb66", req.path_info_fingerprint

      req = sprockets_request(@base.config, "GET", "/lala-0aa2105d29558f3eb790d411d7d8fb66lkasdkketw.js")
      assert_equal nil, req.path_info_fingerprint
    end

    should "know it's asset_path" do
      req = sprockets_request(@base.config, "GET", "/javascripts/lala.js")
      assert_equal "lala.js", req.asset_path

      req = sprockets_request(@base.config, "GET", "/lala.awesome.js")
      assert_equal "lala.awesome.js", req.asset_path

      req = sprockets_request(@base.config, "GET", "/stylesheets/lala.css")
      assert_equal "stylesheets/lala.css", req.asset_path

      req = sprockets_request(@base.config, "GET", "/lala-3462346246.js")
      assert_equal "lala.js", req.asset_path
    end

    should "pass on non-GET forbidden requests for hosted non-media resources" do
      req = sprockets_request(@base.config, "POST", "/javascripts/../alert_one.html")
      assert_not req.valid?
    end

    should "pass on non-GET forbidden requests for hosted media resources" do
      req = sprockets_request(@base.config, "POST", "/javascripts/../alert_one.js")
      assert_not req.valid?
    end

    should "pass on non-GET forbidden requests for not-hosted non-media resources" do
      req = sprockets_request(@base.config, "POST", "/something/../alert_one.html")
      assert_not req.valid?
    end

    should "pass on non-GET forbidden requests for not-hosted media resources" do
      req = sprockets_request(@base.config, "POST", "/something/../alert_one.js")
      assert_not req.valid?
    end


    should "pass on non-GET allowed requests for hosted non-media resources" do
      req = sprockets_request(@base.config, "POST", "/javascripts/alert_one.html")
      assert_not req.valid?
    end

    should "pass on non-GET allowed requests for hosted media resources" do
      req = sprockets_request(@base.config, "POST", "/javascripts/alert_one.js")
      assert_not req.valid?
    end

    should "pass on non-GET allowed requests for not-hosted non-media resources" do
      req = sprockets_request(@base.config, "POST", "/something/alert_one.html")
      assert_not req.valid?
    end

    should "pass on non-GET allowed requests for not-hosted media resources" do
      req = sprockets_request(@base.config, "POST", "/something/alert_one.js")
      assert_not req.valid?
    end


    should "pass on GET forbidden requests for hosted non-media resources" do
      req = sprockets_request(@base.config, "GET", "/javascripts/../alert_one.html")
      assert_not req.valid?
    end

    should "pass on GET forbidden requests for hosted media resources" do
      req = sprockets_request(@base.config, "GET", "/javascripts/../alert_one.js")
      assert_not req.valid?
    end

    should "pass on GET forbidden requests for not-hosted non-media resources" do
      req = sprockets_request(@base.config, "GET", "/something/../alert_one.html")
      assert_not req.valid?
    end

    should "pass on GET forbidden requests for not-hosted media resources" do
      req = sprockets_request(@base.config, "GET", "/something/../alert_one.js")
      assert_not req.valid?
    end


    should "pass on GET allowed requests for hosted non-media resources" do
      req = sprockets_request(@base.config, "GET", "/javascripts/alert_one.html")
      assert_not req.valid?
    end

    should "accept GET allowed requests for hosted media resources" do
      req = sprockets_request(@base.config, "GET", "/javascripts/alert_one.js")
      assert req.valid?
    end

    should "pass on GET allowed requests for not-hosted non-media resources" do
      req = sprockets_request(@base.config, "GET", "/something/alert_one.html")
      assert_not req.valid?
    end

    should "pass on GET allowed requests for not-hosted media resources" do
      req = sprockets_request(@base.config, "GET", "/something/alert_one.js")
      assert_not req.valid?
    end

    should "complain if validating an invalid request" do
      assert_raises NotSprocketsRequest do
        sprockets_request(@base.config, "GET", "/something/alert_one.js").validate!
      end
    end

  end

end
