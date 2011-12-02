class Rack::Sprockets::Config

  class BaseHandler

    attr_accessor :actual

    def initialize(value)
      self.actual = value
    end

    def ==(other)
      self.actual == other.actual
    end

  end

  class HostedAt < BaseHandler

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

  class Cache < BaseHandler

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
        Rack::Sprockets::Config.file_cache_store(@config.root, File.join([
          @config.public.to_s,
          @config.hosted_at.to_s
        ]))
      elsif self.actual.kind_of?(::String)
        # file cache store with custom root
        Rack::Sprockets::Config.file_cache_store(@config.root, self.actual)
      else
        # custom cache store
        self.actual
      end
    end

  end

  class MimeTypes < BaseHandler

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
      (self.media_types & ([*media_type_list] || [])).size > 0
    end
    alias_method :accept?, :for_media_type?

  end

end

