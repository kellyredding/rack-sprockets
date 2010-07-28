require 'test_helper'
require 'rack/sprockets/source'

class SourceTest < Test::Unit::TestCase
  context 'Rack::Sprockets::Source' do
    setup do
      @source_folder = file_path('test','fixtures','sinatra','app','javascripts')
      @secretary = {
        :root => file_path('test','fixtures','sinatra'),
        :load_path => ['app/javascripts']
      }
      @cache = file_path('test','fixtures','sinatra','public','javascripts')
    end

    should "accept the .js file extension" do
      assert_equal [:js], Rack::Sprockets::Source::PREFERRED_EXTENSIONS
    end
    
    context "object" do
      setup do
        @basic = Rack::Sprockets::Source.new('basic', {
          :folder => @source_folder,
          :secretary => @secretary
        })
        @compressed = Rack::Sprockets::Source.new('compressed', {
          :folder => @source_folder,
          :secretary => @secretary,
          :compress => :whitespace
        })
        @cached = Rack::Sprockets::Source.new('cached', {
          :folder => @source_folder,
          :secretary => @secretary,
          :cache => @cache,
          :compress => false
        })
      end
      
      should "have accessors for name and cache values" do 
        assert_respond_to @basic, :js_name
        assert_equal 'basic', @basic.js_name
        assert_respond_to @basic, :cache
      end
      
      should "have an option for using compression" do
        assert_equal false, @basic.compress?, 'the basic app should not compress'
        assert_equal true, @compressed.compress?, 'the compressed app should compress'
      end
      
      should "have an option for caching output to files" do
        assert_equal false, @basic.cache?, 'the basic app should not cache'
        assert_equal true, @cached.cache?, 'the cached app should cache'
      end

      should "have a secretary" do
        assert_respond_to @basic, :secretary, 'source does not respond to :secretary'
        assert_kind_of Sprockets::Secretary, @basic.secretary, 'the source :secretary is not a Sprockets::Secretary'
      end

      should "have a source files list" do
        assert_respond_to @basic, :files, 'source does not respond to :files'
        assert_kind_of Array, @basic.files, 'the source :files is not an Array'
      end

      should "have compiled js" do
        assert_respond_to @basic, :to_js, 'source does not respond to :to_js'
        assert_respond_to @basic, :js, 'source does not respond to :js'
      end
    end
    
    context "with no corresponding source" do
      setup do
        @none = Rack::Sprockets::Source.new('none', {
          :folder => @source_folder,
          :secretary => @secretary
        })
      end

      should "have an empty file list" do
        assert @none.files.empty?, 'source file list is not empty'
      end

      should "generate no js" do
        assert @none.to_js.empty?, 'source generated js when it should not have'
      end
    end

    should_compile_source('app', "needing to be compiled")

    context "with whitespace compression" do
      setup do
        @compiled = File.read(File.join(@source_folder, "app_compiled.js"))
        @compressed_normal = Rack::Sprockets::Source.new('app', {
          :folder => @source_folder,
          :secretary => @secretary,
          :compress => :whitespace
        })
      end

      should "compress the compiled js" do
        assert_equal @compiled.strip.delete("\n"), @compressed_normal.to_js, "the compiled js is compressed incorrectly"
      end
    end

    context "with yui compression" do
      setup do
        @compiled = File.read(File.join(@source_folder, "app_compiled.js"))
        @compressed_normal = Rack::Sprockets::Source.new('app', {
          :folder => @source_folder,
          :secretary => @secretary,
          :compress => :yui
        })
      end

      should "compress the compiled js" do
        comp = YUI::JavaScriptCompressor.new(Rack::Sprockets::Source::YUI_OPTS).compress(@compiled.strip)
        assert_equal comp, @compressed_normal.to_js, "the compiled js is compressed incorrectly"
      end
    end

    context "with caching" do
      setup do
        @expected = Rack::Sprockets::Source.new('app', {
          :folder => @source_folder,
          :secretary => @secretary,
          :cache => @cache
        }).to_js
        @cached_file = File.join(@cache, "app.js")
      end
      teardown do
        FileUtils.rm(@cached_file) if File.exists?(@cached_file)
      end

      should "store the compiled js to a file in the cache" do
        assert File.exists?(@cache), 'the cache folder does not exist'
        assert File.exists?(@cached_file), 'the js was not cached to a file'
        assert_equal @expected.strip, File.read(@cached_file).strip, "the compiled js is incorrect"
      end
    end

  end
end
