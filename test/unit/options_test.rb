require 'test_helper'
require 'rack/sprockets/options'
require 'fixtures/mock_options'

class OptionsTest < Test::Unit::TestCase
  context 'Rack::Sprockets::Options' do
    setup { @options = MockOptions.new }
    
    should "use a namespace" do
      assert_equal 'rack-sprockets', Rack::Sprockets::Options::RACK_ENV_NS
    end
    
    should "provide an option_name helper" do
      assert_respond_to MockOptions, :option_name
    end

    should "provide defaults" do
      assert_respond_to MockOptions, :defaults
    end
    
    should "allow access to the options" do
      assert_respond_to @options, :options, 'no #options accessor'
      assert_kind_of Hash, @options.options, '#options is not a Hash'
      assert_equal MockOptions.defaults[MockOptions.option_name(:source)], @options.options(:source)
    end
    
    { :root => ".",
      :public => 'public',
      :source => 'app/javascripts',
      :hosted_at => '/javascripts',
      :load_path => ["app/javascripts/", "vendor/javascripts/"],
      :expand_paths => true
    }.each do |k,v|
      should "default #{k} correctly" do
        assert_equal v, @options.options[MockOptions.option_name(k)]
      end
    end
    
    context '#set' do
      should "set a Symbol option as #{Rack::Sprockets::Options::RACK_ENV_NS}.symbol" do
        @options.set :foo, 'bar'
        assert_equal 'bar', @options.options[MockOptions.option_name(:foo)]
      end
      should 'set a String option as string' do
        @options.set 'foo.bar', 'baz'
        assert_equal 'baz', @options.options['foo.bar']
      end
      should 'set all key/value pairs when given a Hash' do
        @options.set :foo => 'bar', 'foo.bar' => 'baz'
        assert_equal 'bar', @options.options[MockOptions.option_name(:foo)]
        assert_equal 'baz', @options.options['foo.bar']
      end
    end

    should 'allow setting multiple options via assignment' do
      @options.options = { :foo => 'bar', 'foo.bar' => 'baz' }
      assert_equal 'bar', @options.options[MockOptions.option_name(:foo)]
      assert_equal 'baz', @options.options['foo.bar']
    end

    context "when writing to collection options" do
      setup do
        @option = Rack::Sprockets::Options::COLLECTION_OPTS.first
      end
      
      should "force the option to an array value" do
        @options.set @option, ["blah", "whatever"]
        assert_kind_of Array, @options.options[@option]
        assert_equal 2, @options.options[@option].length
        
        @options.set @option, "something"
        assert_kind_of Array, @options.options[@option]
        assert_equal 1, @options.options[@option].length
      end
    end

  end
end
