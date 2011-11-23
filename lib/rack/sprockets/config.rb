require 'sprockets'
require 'ns-options'

module Rack::Sprockets

  # return a sprockets file store for caching
  # * if begin with '/', treat location as absolute path
  #   otherwise treat location as relative to the :root
  # * remove duplicate '/'
  # * remove any trailing '/'
  def self.file_cache_store(root, location)
    ::Sprockets::Cache::FileStore.new(if location =~ /^\//
      location
    else
      File.join(root, location)
    end.gsub(/\/+/, '/').sub(/\/+$/, ''))
  end

  module Config

    # Handles options for Rack::Sprockets
    # Available options:
    # => root
    #    The app root.  The reference point for
    #    the source and load_path options.  The
    #    Sprockets::Environment is created with
    #    this value
    # => public
    #    The path where static files are located.
    # => hosted_at (prefix)
    #    The public hosted HTTP path root for assets.
    #    The equivalient of the asset prefix in Rails
    #    asset pipeline.
    # => cache
    #    Directive for if/how to cache.  Defaults to `false`.
    #    Set `true` to cache to a Sprockets::Cache::FileStore on
    #    options(:root)/options(:public)/options(:hosted_at).
    #    Set to a string path to use a file store on that path.
    #    Set to any cache store to use a custom cache store
    # => load_path
    #    An ordered array of directory names (relative
    #    to the root option) to search for dependencies in.
    #    Each path will be appended to the sprockets env
    # => logger
    # => version
    # => debug
    # => digest
    # => digest_class
    # => compress
    # => js_compressor
    # => css_compressor
    #    These all map directly to the Sprockets Environment

    def self.included(receiver)
      # ns options collection for middleware config
      receiver.send :include, NsOptions
      receiver.options :config do
        option :root,           Pathname,        :default => '.'
        option :hosted_at,      HostedAtConfig,  :default => '/'
        option :cache,          CacheConfig,     {
          :default => false,
          :args => self
        }
        option :mime_types,     MimeTypesConfig, :default => [
          ['application/javascript', '.js'],
          ['text/css', '.css']
        ]
        option :public,         :default => 'public'
        option :load_path,      :default => []
        # option :debug,          :default => false
        # option :digest,         :default => false
        # option :compress,       :default => false

        # Sprockets pass-thru configs (#=> <sprockets default value>)
        option :digest_class,   :default => nil   #=> ::Digest::MD5
        option :version,        :default => nil   #=> ''
        option :logger,         :default => nil   #=> $stderr, fatal

        option :js_compressor,  :default => nil
        option :css_compressor, :default => nil
      end
    end

    private

    def validate_config!
      # ensure a root path is specified and does exists
      raise(ArgumentError, "no :root option") if self.config.root.nil?

      # ensure a load path is specified and not empty
      raise(ArgumentError, "no :load_path option") if self.config.load_path.nil?
      raise(ArgumentError, "empty :load_path option") if self.config.load_path.empty?
    end

    def configured_sprockets_env
      ::Sprockets::Environment.new(self.config.root) do |e|
        # apply the load_path config
        self.config.load_path.each { |p| e.append_path(p) }

        # apply any cache config
        e.cache = self.config.cache

        # apply any passthru configs
        passthru_configs.each { |k, v| e.send("#{k}=", v) }
      end
    end

    # only pass-thru configs to sprockets that are not nil
    # and are not handled by rack-sprockets directly
    def passthru_configs
      self.config.to_hash.reject do |k,v|
        v.nil? || [ :root, :public, :hosted_at, :mime_types,
          :load_path, :cache
        ].include?(k)
      end
    end



    class CustomConfig

      attr_accessor :actual

      def initialize(value)
        self.actual = value
      end

      def ==(other)
        self.actual == other.actual
      end

    end



    class HostedAtConfig < CustomConfig

      # sanitized :hosted_at config
      #  remove any trailing '/'
      #  ensure single leading '/'
      def actual=(value)
        super(value.sub(/\/+$/, '').sub(/^\/*/, '/'))
      end

      def to_s
        self.actual.to_s
      end

    end



    class CacheConfig < CustomConfig

      def initialize(value, config)
        super(value)
        @config = config
      end

      # accept a variety of directives for setting up caching (if any)
      # * `false` for no caching (default)
      # * `true`cache to a default file store in :root/:public/:hosted_at
      # * `<string path>` cache to file store in custom path
      # * `<cache store obj>` cache to a custom cache store
      def store
        @store ||= if self.actual == false
          # no caching
          nil
        elsif self.actual == true
          # default file cache store at :public/:hosted_at
          Rack::Sprockets.file_cache_store(@config.root, File.join([
            @config.public.to_s,
            @config.hosted_at.to_s
          ]))
        elsif self.actual.kind_of?(::String)
          # file cache store with custom root
          Rack::Sprockets.file_cache_store(@config.root, self.actual)
        else
          # custom cache store
          self.actual
        end
      end

    end



    class MimeTypesConfig < CustomConfig

      attr_reader :formats, :media_types

      # receive media type config as a list of media type tuples
      # * the first item in each is the media type string
      # * the second item in each is the format string
      def actual=(value)
        super(value)
        @media_types = self.actual.map { |mt_f| mt_f[0] }
        @formats = self.actual.map { |mt_f| mt_f[1] }
      end

      def for_format?(format)
        self.formats.include?(format)
      end

      def for_media_type?(media_type_list)
        (self.media_types & media_type_list).size > 0
      end
      alias_method :accept?, :for_media_type?

    end



  end
end
