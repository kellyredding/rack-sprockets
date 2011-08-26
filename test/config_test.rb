require 'assert'
require 'rack/sprockets/config'

module Rack::Sprockets

  class ConfigTests < Assert::Context
    desc 'Rack::Sprockets::Config'
    setup do
      @config = Config.new
    end
    subject { @config }

    should have_accessors :cache, :compress

    should "provide boolean readers" do
      assert_respond_to :cache?, @config, "no reader for :cache?"
      assert_equal !!@config.cache, @config.cache?
      assert_respond_to :compress?, @config, "no reader for :compress?"
      assert_equal !!@config.compress, @config.compress?
    end

    should "allow init with setting hash" do
      settings = {
        :cache => true,
        :compress => true
      }
      config = Config.new settings

      assert_equal true, config.cache
      assert_equal true, config.compress
    end

    should "be accessible at Rack::Sprockets class level" do
      assert_respond_to :configure, Rack::Sprockets
      assert_respond_to :config, Rack::Sprockets
      assert_respond_to :config=, Rack::Sprockets
    end

  end

  class ConfigSettingsTests < Assert::Context
    desc "given a new configuration"
    setup do
      @old_config = Rack::Sprockets.config
      @settings = {
        :cache => true,
        :compress => true,
      }
      @traditional_config = Config.new @settings
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
