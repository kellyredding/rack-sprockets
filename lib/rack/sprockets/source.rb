require 'sprockets'

begin
  require "yui/compressor"
rescue LoadError
  # only error about missing yui compressor if
  # :yui compression is requested
end

module Rack::Sprockets

  class Source
    
    PREFERRED_EXTENSIONS = [:js]
    SECRETARY_DEFAULTS = {
      :expand_paths => true
    }
    YUI_OPTS = {
      :munge => true
    }
    
    attr_reader :js_name
    
    def initialize(js_name, options={})
      @js_name  = js_name
      @compress = options[:compress]
      @cache    = options[:cache]

      @folder   = get_required_path(options, :folder)
      @secretary = SECRETARY_DEFAULTS.merge(options[:secretary] || {})
    end
    
    def compress?
      !!@compress
    end
    def cache?
      !@cache.nil?
    end
    def cache
      @cache
    end
    
    def files
      @files ||= js_sources
    end    
    
    def secretary
      @secretary_obj ||= Sprockets::Secretary.new(@secretary.merge({
        :source_files => files
      }))
    end

    def compiled
      @compiled ||= begin
        compiled_js = secretary.concatenation.to_s
        
        compiled_js = case @compress
        when :whitespace, true
          compiled_js.delete("\n")
        when :yui
          if defined?(YUI::JavaScriptCompressor)
            YUI::JavaScriptCompressor.new(YUI_OPTS).compress(compiled_js)
          else
            raise LoadError, "YUI::JavaScriptCompressor is not available. Install it with: gem install yui-compressor"
          end
        else
          compiled_js
        end

        if cache? && !File.exists?(cf = File.join(@cache, "#{@js_name}.js"))
          FileUtils.mkdir_p(File.dirname(cf))
          File.open(cf, "w") do |file|
            file.write(compiled_js)
          end
        end
        
        compiled_js
      end
    end
    alias_method :to_js, :compiled
    alias_method :js, :compiled
    
    protected
    
    # Source files matching the js name
    def js_sources
      @js_sources ||= preferred_sources([*@js_name])
    end
    
    private
    
    # Given a list of file names, return a list of
    # existing source files with the corresponding names
    # honoring the preferred extension list
    def preferred_sources(file_names)
      file_names.collect do |name|
        PREFERRED_EXTENSIONS.inject(nil) do |source_file, extension|
          source_file || begin
            path = File.join(@folder, "#{name}.#{extension}")
            File.exists?(path) ? path : nil
          end
        end
      end.compact
    end
    
    def get_required_path(options, path_key)
      unless options.has_key?(path_key)
        raise(ArgumentError, "no :#{path_key} option specified")
      end
      unless File.exists?(options[path_key])
        raise(ArgumentError, "the :#{path_key} ('#{options[path_key]}') does not exist") 
      end
      options[path_key]
    end

  end
  
end
