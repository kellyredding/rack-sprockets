require 'sprockets'
require 'ns-options'

module Rack::Sprockets; end
require 'rack/sprockets/config/config_handlers'

class Rack::Sprockets::Config
  include NsOptions::Proxy

  def initialize(configs={})
    self.apply(configs || {})
  end

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

  option :root,           Pathname,  :default => '.'
  option :hosted_at,      HostedAt,  :default => '/'
  option :cache,          Cache,     {
    :default => false,
    :args => self
  }
  option :mime_types,     MimeTypes, :default => [
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

  def validate!
    # ensure a root path is specified and does exists
    raise(ArgumentError, "no :root option") if self.root.nil?

    # ensure a load path is specified and not empty
    raise(ArgumentError, "no :load_path option") if self.load_path.nil?
    raise(ArgumentError, "empty :load_path option") if self.load_path.empty?
  end

  def sprockets_env
    ::Sprockets::Environment.new(self.root) do |e|
      # apply the load_path config
      self.load_path.each { |p| e.append_path(p) }

      # apply any cache config
      e.cache = self.cache

      # apply any passthru configs
      passthru_configs.each { |k, v| e.send("#{k}=", v) }
    end
  end

  private

  # only pass-thru configs to sprockets that are not nil
  # and are not handled by rack-sprockets directly
  def passthru_configs
    self.to_hash.reject do |k,v|
      v.nil? || [ :root, :public, :hosted_at, :mime_types,
        :load_path, :cache,
        :sprockets
      ].include?(k)
    end
  end

end
