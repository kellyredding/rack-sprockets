require 'test_helper'
require 'rack/sprockets/base'
require 'rack/sprockets/request'

class RequestTest < Test::Unit::TestCase

  context 'Rack::Sprockets::Request' do
    setup do 
      @defaults = env_defaults
    end
    
    context "basic object" do
      should "have some attributes" do
        [ :options,
          :request_method,
          :path_info,
          :path_resource_name,
          :path_resource_format,
          :source,
          :for_js?,
          :for_sprockets?
        ].each do |a|
          assert_respond_to sprockets_request("GET", "/foo.js"), a, "request does not respond to #{a.inspect}"
        end   
      end
      
      should "know it's resource name" do
        assert_equal 'foo', sprockets_request("GET", "/foo.js").path_resource_name
        assert_equal 'bar', sprockets_request("GET", "/foo/bar.js").path_resource_name
      end
      
      should "know it's resource format" do
        assert_equal '.js', sprockets_request("GET", "/foo.js").path_resource_format
        assert_equal '.js', sprockets_request("GET", "/foo/bar.js").path_resource_format
      end
    end
    
    context "#source " do
      should "match :compress settings with Rack::Sprockets:Config" do
        req = sprockets_request("GET", "/javascripts/app.js")
        assert_equal Rack::Sprockets.config.compress?, req.source.compress?
      end
      
      should "set it's cache value to nil when Rack::Sprockets not configured to cache" do
        Rack::Sprockets.config = Rack::Sprockets::Config.new
        req = sprockets_request("GET", "/javascripts/app.js")

        assert_equal false, req.source.cache?
        assert_equal nil, req.source.cache
      end

      should "set it's cache to the appropriate path when Rack::Sprockets configured to cache" do
        Rack::Sprockets.config = Rack::Sprockets::Config.new :cache => true
        req = sprockets_request("GET", "/javascripts/app.js")
        cache_path = File.join(req.options(:root), req.options(:public), req.options(:hosted_at))
        
        assert_equal true, req.source.cache?
        assert_equal cache_path, req.source.cache
      end
    end
    
    should_not_be_a_valid_rack_sprockets_request({
      :method      => "POST",
      :resource    => "/foo.html",
      :description => "a non-js resource"
    })

    should_not_be_a_valid_rack_sprockets_request({
      :method      => "POST",
      :resource    => "/foo.css",
      :description => "a css resource"
    })
    
    should_not_be_a_valid_rack_sprockets_request({
      :method      => "GET",
      :resource    => "/foo.html",
      :description => "a non-js resource"
    })
    
    should_not_be_a_valid_rack_sprockets_request({
      :method      => "GET",
      :resource    => "/foo.js",
      :description => "a js resource hosted somewhere other than where Rack::Sprockets expects them"
    })

    should_not_be_a_valid_rack_sprockets_request({
      :method      => "GET",
      :resource    => "/javascripts/foo.js",
      :description => "a js resource hosted where Rack::Sprockets expects them but does not match any source"
    })

    should_be_a_valid_rack_sprockets_request({
      :method      => "GET",
      :resource    => "/javascripts/app.js",
      :description => "a js resource hosted where Rack::Sprockets expects them that matches source"
    })
  end

end
