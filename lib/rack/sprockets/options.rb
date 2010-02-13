module Rack::Sprockets
  module Options
    
    # Handles options for Rack::Sprockets
    # Available options:
    # => root
    #    The app root.  The reference point for
    #    the source and public options.  Maps to
    #    the `:root` Sprockets option.
    # => public
    #    The path where static files are located.
    #    Maps to the `:asset_root` Sprockets option.
    # => source
    #    The path where Sprockets source files are
    #    located.  Notice this does not map to the
    #    `:source_files` Sprockets option.  It is
    #    assumed that any requested resource found
    #    in `:source` be treated as a Sprockets
    #    source file.
    # => hosted_at
    #    The public hosted HTTP path for static
    #    javascripts files.
    # => load_path
    #    An ordered array of directory names to
    #    search for dependencies in.  Maps to the
    #    `:load_path` Sprockets option.
    # => expand_paths
    #    Whether or not to expand filenames according
    #    to shell glob rules.  Maps to the
    #    `:expand_paths` Sprockets option.
    
    RACK_ENV_NS = "rack-sprockets"
    
    module ClassMethods
      
      def defaults
        {
          option_name(:root)         => ".",
          option_name(:public)       => 'public',
          option_name(:source)       => 'app/javascripts',
          option_name(:hosted_at)    => '/javascripts',
          option_name(:load_path)    => [
            "app/javascripts/",
            "vendor/javascripts/"
          ],
          option_name(:expand_paths) => true
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
        options[option_name(key)] = value
      end

    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
    
  end
end