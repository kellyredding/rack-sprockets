require 'assert'
require 'rack/sprockets/source'

module Rack::Sprockets

  class SourceTests < Assert::Context
    desc 'Rack::Sprockets::Source'
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

    setup do
      @basic = Source.new('basic', {
        :folder => @source_folder,
        :secretary => @secretary
      })
      @nested1 = Source.new('something/nested', {
        :folder => @source_folder,
        :secretary => @secretary
      })
      @nested2 = Source.new('/other/nested', {
        :folder => @source_folder,
        :secretary => @secretary
      })
      @nested3 = Source.new('///wrong/nested', {
        :folder => @source_folder,
        :secretary => @secretary
      })
      @compressed = Source.new('compressed', {
        :folder => @source_folder,
        :secretary => @secretary,
        :compress => :whitespace
      })
      @cached = Source.new('cached', {
        :folder => @source_folder,
        :secretary => @secretary,
        :cache => @cache,
        :compress => false
      })
    end

    should "have accessors for js_resource and cache values" do
      assert_respond_to :js_resource, @basic
      assert_equal 'basic', @basic.js_resource
      assert_respond_to :cache, @basic
    end

    should "handle nested js_resource" do
      assert_equal 'something/nested', @nested1.js_resource
    end

    should "strip any leading '/' on js_resource" do
      assert_equal 'other/nested', @nested2.js_resource
      assert_equal 'wrong/nested', @nested3.js_resource
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
      assert_respond_to :secretary, @basic, 'source does not respond to :secretary'
      assert_kind_of Sprockets::Secretary, @basic.secretary, 'the source :secretary is not a Sprockets::Secretary'
    end

    should "have a source files list" do
      assert_respond_to :files, @basic, 'source does not respond to :files'
      assert_kind_of Array, @basic.files, 'the source :files is not an Array'
    end

    should "have compiled js" do
      assert_respond_to :to_js, @basic, 'source does not respond to :to_js'
      assert_respond_to :js, @basic, 'source does not respond to :js'
    end

    should "whitespace compress the compiled js" do
      @compiled = File.read(File.join(@source_folder, "app_compiled.js"))
      @compressed_normal = Rack::Sprockets::Source.new('app', {
        :folder => @source_folder,
        :secretary => @secretary,
        :compress => :whitespace
      })

      assert_equal @compiled.strip.delete("\n"), @compressed_normal.to_js, "the compiled js is compressed incorrectly"
    end

    should "yui compress the compiled js" do
      @compiled = File.read(File.join(@source_folder, "app_compiled.js"))
      @compressed_normal = Rack::Sprockets::Source.new('app', {
        :folder => @source_folder,
        :secretary => @secretary,
        :compress => :yui
      })

      comp = YUI::JavaScriptCompressor.new(Rack::Sprockets::Source::YUI_OPTS).compress(@compiled.strip)
      assert_equal comp, @compressed_normal.to_js, "the compiled js is compressed incorrectly"
    end

    should "store the compiled js to a file in the cache" do
      FileUtils.rm_rf(File.dirname(@cache)) if File.exists?(File.dirname(@cache))
      @expected = Rack::Sprockets::Source.new('app', {
        :folder => @source_folder,
        :secretary => @secretary,
        :cache => @cache
      }).to_js
      @cached_file = File.join(@cache, "app.js")

      assert File.exists?(@cache), 'the cache folder does not exist'
      assert File.exists?(@cached_file), 'the js was not cached to a file'
      assert_equal @expected.strip, File.read(@cached_file).strip, "the compiled js is incorrect"

      FileUtils.rm_rf(File.dirname(@cache)) if File.exists?(File.dirname(@cache))
    end

  end

  class NoSourceTests < SourceTests
    desc "with no corresponding source"
    setup do
      @none = Source.new('none', {
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

  class CompileTests < SourceTests
    should_compile_source('app', "needing to be compiled")
  end

end
