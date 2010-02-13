require 'rubygems'
require 'test/unit'
require 'shoulda'

# Add test and lib paths to the $LOAD_PATH
[ File.dirname(__FILE__),
  File.join(File.dirname(__FILE__), '..', 'lib')
].each do |path|
  full_path = File.expand_path(path)
  $LOAD_PATH.unshift(full_path) unless $LOAD_PATH.include?(full_path)
end

require 'rack/sprockets'

class Test::Unit::TestCase
  
  def file_path(*segments)
    segs = segments.unshift([File.dirname(__FILE__), '..']).flatten
    File.expand_path(segs.join(File::SEPARATOR))
  end
  
  def env_defaults
    Rack::Sprockets::Base.defaults.merge({
      Rack::Sprockets::Base.option_name(:root) => file_path('test','fixtures','sinatra')
    })
  end
  
  def sprockets_request(method, path_info)
    Rack::Sprockets::Request.new(@defaults.merge({
      'REQUEST_METHOD' => method,
      'PATH_INFO' => path_info
    }))
  end
  
  def sprockets_response(js)
    Rack::Sprockets::Response.new(@defaults, js)
  end
  
  def self.should_not_be_a_valid_rack_less_request(args)
    context "to #{args[:method].upcase} #{args[:resource]} (#{args[:description]})" do
      setup do 
        @request = sprockets_request(args[:method], args[:resource])
      end
      
      should "not be a valid endpoint for Rack::Less" do
        not_valid = !@request.get?
        not_valid ||= !@request.for_js?
        not_valid ||= @request.source.files.empty?
        assert not_valid, 'request is a GET for .css format and has source'
        assert !@request.for_less?, 'the request is for less'
      end
    end
  end
  def self.should_be_a_valid_rack_less_request(args)
    context "to #{args[:method].upcase} #{args[:resource]} (#{args[:description]})" do
      setup do 
        @request = less_request(args[:method], args[:resource])
      end
      
      should "be a valid endpoint for Rack::Less" do
        assert @request.get?, 'the request is not a GET'
        assert @request.for_css?, 'the request is not for css'
        assert !@request.source.files.empty?, 'the request resource has no source'
        assert @request.for_css?, 'the request is not for css'
        assert @request.for_less?, 'the request is not for less'
      end
    end
  end
  
end