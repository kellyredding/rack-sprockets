# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rack-sprockets}
  s.version = "1.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kelly Redding"]
  s.date = %q{2010-08-05}
  s.email = %q{kelly@kelredd.com}
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc", "Rakefile", "lib/rack", "lib/rack/sprockets", "lib/rack/sprockets/base.rb", "lib/rack/sprockets/config.rb", "lib/rack/sprockets/options.rb", "lib/rack/sprockets/request.rb", "lib/rack/sprockets/response.rb", "lib/rack/sprockets/source.rb", "lib/rack/sprockets/version.rb", "lib/rack/sprockets.rb"]
  s.homepage = %q{http://github.com/kelredd/rack-sprockets}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Sprockets javascript preprocessing for Rack apps.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<shoulda>, [">= 2.10.0"])
      s.add_development_dependency(%q<sinatra>, [">= 0.9.4"])
      s.add_development_dependency(%q<rack-test>, [">= 0.5.3"])
      s.add_development_dependency(%q<webrat>, [">= 0.6.0"])
      s.add_development_dependency(%q<yui-compressor>, [">= 0.9.1"])
      s.add_runtime_dependency(%q<rack>, [">= 0.4"])
      s.add_runtime_dependency(%q<sprockets>, [">= 1.0.0"])
    else
      s.add_dependency(%q<shoulda>, [">= 2.10.0"])
      s.add_dependency(%q<sinatra>, [">= 0.9.4"])
      s.add_dependency(%q<rack-test>, [">= 0.5.3"])
      s.add_dependency(%q<webrat>, [">= 0.6.0"])
      s.add_dependency(%q<yui-compressor>, [">= 0.9.1"])
      s.add_dependency(%q<rack>, [">= 0.4"])
      s.add_dependency(%q<sprockets>, [">= 1.0.0"])
    end
  else
    s.add_dependency(%q<shoulda>, [">= 2.10.0"])
    s.add_dependency(%q<sinatra>, [">= 0.9.4"])
    s.add_dependency(%q<rack-test>, [">= 0.5.3"])
    s.add_dependency(%q<webrat>, [">= 0.6.0"])
    s.add_dependency(%q<yui-compressor>, [">= 0.9.1"])
    s.add_dependency(%q<rack>, [">= 0.4"])
    s.add_dependency(%q<sprockets>, [">= 1.0.0"])
  end
end
