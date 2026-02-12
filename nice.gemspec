Gem::Specification.new do |spec|
  spec.name          = "nice"
  spec.version       = "0.1.0"
  spec.authors       = ["Nicolas Leger"]
  spec.email         = ["your.email@example.com"]

  spec.summary       = "OpenData NCA - Métropole Nice Côte d'Azur"
  spec.description   = "A Ruby gem for accessing and managing OpenData from Nice Côte d'Azur metropolitan area via CKAN API"
  spec.homepage      = "https://github.com/nicolasleger/nice"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/nicolasleger/nice"
  spec.metadata["changelog_uri"] = "https://github.com/nicolasleger/nice/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # CKAN dependency
  spec.add_dependency "ckan"
  
  # Additional useful dependencies
  spec.add_dependency "httparty", "~> 0.21"
  spec.add_dependency "json", "~> 2.6"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "vcr", "~> 6.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.14"
  spec.add_development_dependency "pry-byebug", "~> 3.10"
end
