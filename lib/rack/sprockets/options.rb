module Rack::Sprockets
  module Options

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
    # => load_path
    #    An ordered array of directory names (relative
    #    to the root option) to search for dependencies in.
    #    Each path will be appended to the sprockets env
    # => version
    # => debug
    # => digest
    # => compress
    # => js_compressor
    # => css_compressor
    #    These all map directly to the Sprockets Environment

    RACK_ENV_NS = "rack-sprockets"
    COLLECTION_OPTS = ["#{RACK_ENV_NS}.load_path"]

    module ClassMethods

      def defaults
        {
          option_name(:root)        => ".",
          option_name(:public)      => 'public',
          option_name(:hosted_at)   => '/assets',
          option_name(:load_path)   => [
            "app/assets/",
            "lib/assets/",
            "vendor/assets/"
          ],
          option_name(:version)         => nil,
          option_name(:debug)           => false,
          option_name(:digest)          => false,
          option_name(:compress)        => false,
          option_name(:js_compressor)   => nil,
          option_name(:css_compressor)  => nil,
        }
      end

      # Rack::Sprockets uses the Rack Environment to store option values. All options
      # are stored in the Rack Environment as "<RACK_ENV_PREFIX>.<option>", where
      # <option> is the option name.
      def option_name(key)
        case key
        when Symbol ; "#{RACK_ENV_NS}.#{key}"
        when String ; key
        else raise ArgumentError
        end
      end

    end

    module InstanceMethods

      # Rack::Sprockets uses the Rack Environment to store option values. All options
      # are stored in the Rack Environment as "<RACK_ENV_PREFIX>.<option>", where
      # <option> is the option name.
      def option_name(key)
        self.class.option_name(key)
      end

      # The underlying options Hash. During initialization (or outside of a
      # request), this is a default values Hash. During a request, this is the
      # Rack environment Hash. The default values Hash is merged in underneath
      # the Rack environment before each request is processed.
      # => if a key is passed, the option value for the key is returned
      def options(key=nil)
        if key
          (@env || @default_options)[option_name(key)]
        else
          @env || @default_options
        end
      end

      # Set multiple options at once.
      def options=(hash={})
        hash.each { |key,value| write_option(key, value) }
      end

      # Set an option. When +option+ is a Symbol, it is set in the Rack
      # Environment as "rack-cache.option". When +option+ is a String, it
      # exactly as specified. The +option+ argument may also be a Hash in
      # which case each key/value pair is merged into the environment as if
      # the #set method were called on each.
      def set(option, value=nil)
        if value.nil?
          self.options = option.to_hash
        else
          write_option option, value
        end
      end

      private

      def initialize_options(options={})
        @default_options = self.class.defaults
        self.options = options
      end

      def read_option(key)
        options[option_name(key)]
      end

      def write_option(key, value)
        if COLLECTION_OPTS.include?(opt_name = option_name(key))
          options[opt_name] = [*value]
        else
          options[opt_name] = value
        end
      end

    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end

  end
end
