require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'leftright'


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
  
  def self.should_compile_source(name, desc)
    context desc do
      setup do
        @compiled = File.read(File.join(@source_folder, "#{name}_compiled.js"))
        @source = Rack::Sprockets::Source.new(name, {
          :folder => @source_folder,
          :secretary => @secretary
        })
      end
      
      should "compile to Javascript" do
        assert_equal @compiled.strip, @source.compiled.strip, '.compiled is incorrect'
        assert_equal @compiled.strip, @source.to_js.strip, '.to_js is incorrect'
        assert_equal @compiled.strip, @source.js.strip, '.js is incorrect'
      end
    end
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
  
  def self.should_not_be_a_valid_rack_sprockets_request(args)
    context "to #{args[:method].upcase} #{args[:resource]} (#{args[:description]})" do
      setup do 
        @request = sprockets_request(args[:method], args[:resource])
      end
      
      should "not be a valid endpoint for Rack::Sprockets" do
        not_valid = !@request.get?
        not_valid ||= !@request.for_js?
        not_valid ||= @request.source.files.empty?
        assert not_valid, 'request is a GET for .js format and has source'
        assert !@request.for_sprockets?, 'the request is for sprockets'
      end
    end
  end
  def self.should_be_a_valid_rack_sprockets_request(args)
    context "to #{args[:method].upcase} #{args[:resource]} (#{args[:description]})" do
      setup do 
        @request = sprockets_request(args[:method], args[:resource])
      end
      
      should "be a valid endpoint for Rack::Sprockets" do
        assert @request.get?, 'the request is not a GET'
        assert @request.for_js?, 'the request is not for js'
        assert !@request.source.files.empty?, 'the request resource has no source'
        assert @request.for_sprockets?, 'the request is not for sprockets'
      end
    end
  end
  
end