require 'assert'

require 'rack/sprockets/config'
require 'test/fixtures/mock_base'

module Rack::Sprockets::Config

  class BaseTests < Assert::Context
    desc 'Rack::Sprockets::Config'
    setup do
      @base = MockBase.new
      @config = @base.config
    end

    should "default the root to '.'" do
      assert_kind_of Pathname, @config.root
      assert_equal Pathname.new("."), @config.root
    end

    should "default the hosted at to '/'" do
      assert_kind_of HostedAtConfig, @config.hosted_at
      assert_equal HostedAtConfig.new("/"), @config.hosted_at
    end

    should "default the cache to false" do
      assert_kind_of CacheConfig, @config.cache
      assert_equal CacheConfig.new(false, @config), @config.cache
    end

    should "default the mime types to js and css" do
      assert_kind_of MimeTypesConfig, @config.mime_types
      assert_equal(MimeTypesConfig.new([
        ['application/javascript', '.js'],
        ['text/css', '.css']
      ]), @config.mime_types)
    end

    should "default the public location to 'public'" do
      assert_equal 'public', @config.public
    end

    should "default the load path to be empty" do
      assert_equal [], @config.load_path
    end

    should "default the pass-thru Sprockets configs" do
      {
        :digest_class => nil,
        :version => nil,
        :logger => nil,
        :js_compressor => nil,
        :css_compressor => nil
      }.each do |k,v|
        assert_equal v, @config.send(k)
      end
    end

  end



  class ValidateTests < BaseTests
    desc "when validated"
    setup { @config.load_path = ["app"] }

    def assert_validation(error=nil)
      if error
        assert_raises(error)  { @base.send :validate_config! }
      else
        assert_nothing_raised { @base.send :validate_config! }
      end
    end

    should "complain if no root config" do
      assert_validation
      @config.root = nil
      assert_validation(ArgumentError)
    end

    should "complain if no load path config" do
      assert_validation
      @config.load_path = nil
      puts "load_path: #{@config.load_path}"
      assert_validation(ArgumentError)
    end

    should "complain if load path config is empty" do
      assert_validation
      @config.load_path = []
      puts "load_path: #{@config.load_path}"
      assert_validation(ArgumentError)
    end

  end



  class HostedAtConfigTests < BaseTests
    desc 'HostedAtConfig'
    subject { @config.hosted_at }

    should "be a HostedAtConfig obj" do
      assert_kind_of HostedAtConfig, subject
    end

    should "config the default '/' value" do
      assert_equal '/', subject.to_s
    end

    should "remove trailing slashes" do
      @config.hosted_at = '/hosted-here/'
      assert_equal '/hosted-here', subject.to_s
    end

    should "ensure a leading slash" do
      @config.hosted_at = '/hosted'
      assert_equal '/hosted', subject.to_s
      @config.hosted_at = 'hosted'
      assert_equal '/hosted', subject.to_s
    end

  end



  class CacheConfigTests < BaseTests
    desc "CacheConfig"
    subject { @config.cache }

    should have_reader :store

    should "be a CacheConfig obj" do
      assert_kind_of CacheConfig, subject
    end

    should "have no store if false" do
      @config.cache = false
      assert_equal nil, subject.store
    end

    def assert_file_store_at(*args)
      assert_kind_of ::Sprockets::Cache::FileStore, subject.store

      exp_root = if args.size > 1
        File.join(*args.map do |a|
          a.kind_of?(::Symbol) ? @config.send(a).to_s : a
        end)
      else
        args.first
      end.sub(/\/+$/, '')
      act_root = subject.store.instance_variable_get("@root").to_s
      assert_equal exp_root, act_root
    end

    should "return a default file store if :cache is true" do
      @config.cache = true
      assert_file_store_at(:root, :public, :hosted_at)
    end

    should "return a file store on the given path is :cache is a given a relative path string" do
      @config.cache = "tmp/cache"
      assert_file_store_at(:root, 'tmp/cache')
    end

    should "return a file store on the given path is :cache is a given an absolute path string" do
      @config.cache = "/tmp/cache"
      assert_file_store_at('/tmp/cache')
    end

    should "return the given cache store if :cache is a given cache store" do
      store = ::Sprockets::Cache::FileStore.new("/tmp/cache")
      @config.cache = store
      assert_same store, subject.store
    end

  end



  class MimeTypesConfigTests < BaseTests
    desc "MimeTypesConfig"
    setup do
      @custom_types = [['some/format', '.some'], ['another/format', '.another']]
      @config.mime_types = @custom_types
    end
    subject { @config.mime_types }

    should have_readers :formats, :media_types
    should have_instance_methods :for_format?, :accept?, :for_media_type?

    should "know its formats" do
      assert_equal ['.some', '.another'], subject.formats
    end

    should "know its media types" do
      assert_equal ['some/format', 'another/format'], subject.media_types
    end

    should "know if it is for a format or not" do
      assert subject.for_format? '.some'
      assert subject.for_format? '.another'
      assert_not subject.for_format? '.blah'
    end

    should "know if it accepts a media type or not" do
      assert subject.accept? ['another/format']
      assert_not subject.accept? ['unknown/format']
    end

    should "know if it is for a media type of not" do
      assert subject.for_media_type? ['some/format']
      assert_not subject.for_media_type? ['unknown/format']
    end

  end



  class SprocketsEnvTests < BaseTests
    desc "Sprockets env"
    setup do
      @base = MockBase.new({
        :load_path => ["app", "lib"],
        :cache => "/tmp",
        :version => "1.0"
      })
    end
    subject { @base.sprockets_env }

    should "have the load_path applied" do
      @base.config.load_path.each do |path|
        exp_path = File.expand_path("./#{path}", @base.config.root)
        assert_included exp_path, subject.paths
      end
    end

    should "have the cache config applied" do
      assert_equal @base.config.cache, subject.cache
    end

    should "have any passthru configs applied" do
      @base.send(:passthru_configs).each do |k,v|
        assert_equal v, subject.send(k)
      end
    end

  end

end
