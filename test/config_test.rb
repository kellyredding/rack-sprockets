require 'assert'
require 'ns-options/assert_macros'
require 'test/fixtures/mock_base'

require 'rack/sprockets/config'

class Rack::Sprockets::Config

  class BaseTests < Assert::Context
    include NsOptions::AssertMacros

    desc 'Rack::Sprockets::Config'
    setup do
      @config = Rack::Sprockets::Config.new
    end
    subject { @config }

    should have_option :root,           Pathname,  :default => '.'
    should have_option :hosted_at,      HostedAt,  :default => '/'
    should have_option :cache,          Cache,     {
      :default => false,
      :args => Rack::Sprockets::Config
    }
    should have_option :mime_types,     MimeTypes, :default => [
      ['application/javascript', '.js'],
      ['text/css', '.css']
    ]
    should have_option :public,         :default => 'public'
    should have_option :load_path,      :default => []

    should have_option :digest_class,   :default => nil
    should have_option :version,        :default => nil
    should have_option :logger,         :default => nil

    should have_option :js_compressor,  :default => nil
    should have_option :css_compressor, :default => nil

  end



  class ValidateTests < BaseTests
    desc "validated"
    setup { @config.load_path = ["app"] }

    def assert_validation(error=nil)
      if error
        assert_raises(error)  { subject.send :validate! }
      else
        assert_nothing_raised { subject.send :validate! }
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
    desc 'HostedAt config'
    subject { @config.hosted_at }

    should "be a HostedAtConfig obj" do
      assert_kind_of HostedAt, subject
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
    desc "Cache config"
    subject { @config.cache }

    should have_reader :store

    should "be a CacheConfig obj" do
      assert_kind_of Cache, subject
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
    desc "MimeTypes config"
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
      assert_not subject.for_media_type? nil
    end

  end



  class SprocketsEnvTests < BaseTests
    desc "Sprockets env"
    setup do
      @config = Rack::Sprockets::Config.new({
        :load_path => ["app", "lib"],
        :cache => "/tmp",
        :version => "1.0"
      })
    end
    subject { @config.sprockets_env }

    should "have the load_path applied" do
      @config.load_path.each do |path|
        exp_path = File.expand_path("./#{path}", @config.root)
        assert_included exp_path, subject.paths
      end
    end

    should "have the cache config applied" do
      assert_equal @config.cache, subject.cache
    end

    should "have any passthru configs applied" do
      @config.send(:passthru_configs).each do |k,v|
        assert_equal v, subject.send(k)
      end
    end

  end

end
