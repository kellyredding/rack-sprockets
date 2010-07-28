require 'test_helper'
require 'rack/sprockets/config'

class ConfigTest < Test::Unit::TestCase
  context 'Rack::Sprockets::Config' do
    setup do
      @config = Rack::Sprockets::Config.new
    end
    
    { :cache => false,
      :compress => false
    }.each do |k,v|
      should "have an accessor for #{k}" do
        assert_respond_to @config, k, "no reader for #{k}"
        assert_respond_to @config, "#{k}=".to_sym, "no writer for #{k}"
      end

      should "default #{k} correctly" do
        assert_equal v, @config.send(k)
      end      
    end
    
    should "provide boolean readers" do
      assert_respond_to @config, :cache?, "no reader for :cache?"
      assert_equal !!@config.cache, @config.cache?
      assert_respond_to @config, :compress?, "no reader for :compress?"
      assert_equal !!@config.compress, @config.compress?
    end
    
    should "allow init with setting hash" do
      settings = {
        :cache => true,
        :compress => true
      }
      config = Rack::Sprockets::Config.new settings
      
      assert_equal true, config.cache
      assert_equal true, config.compress
    end
    
    should "be accessible at Rack::Sprockets class level" do
      assert_respond_to Rack::Sprockets, :configure
      assert_respond_to Rack::Sprockets, :config
      assert_respond_to Rack::Sprockets, :config=
    end
    
    context "given a new configuration" do
      setup do
        @old_config = Rack::Sprockets.config
        @settings = {
          :cache => true,
          :compress => true,
        }
        @traditional_config = Rack::Sprockets::Config.new @settings
      end
      teardown do
        Rack::Sprockets.config = @old_config
      end
      
      should "allow Rack::Sprockets to directly apply settings" do
        Rack::Sprockets.config = @traditional_config.dup
        
        assert_equal @traditional_config.cache, Rack::Sprockets.config.cache
        assert_equal @traditional_config.compress, Rack::Sprockets.config.compress
      end

      should "allow Rack::Sprockets to apply settings using a block" do
        Rack::Sprockets.configure do |config|
          config.cache  = true
          config.compress = true
        end
        
        assert_equal @traditional_config.cache, Rack::Sprockets.config.cache
        assert_equal @traditional_config.compress, Rack::Sprockets.config.compress
      end
      
    end

  end
end
