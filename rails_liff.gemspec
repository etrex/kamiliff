$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "rails_liff/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "rails_liff"
  spec.version     = RailsLiff::VERSION
  spec.authors     = ["etrex kuo"]
  spec.email       = ["et284vu065k3@gmail.com"]
  spec.homepage    = "https://github.com/etrex/rails_liff"
  spec.summary     = %q{An easy way to use LINE Front-end Framework(LIFF) on rails.}
  spec.description = %q{An easy way to use LINE Front-end Framework(LIFF) on rails.}
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "http://mygemserver.com"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 5.2.2"
end
