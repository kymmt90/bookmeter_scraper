lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bookmeter_scraper/version'

Gem::Specification.new do |spec|
  spec.name          = "bookmeter_scraper"
  spec.version       = BookmeterScraper::VERSION
  spec.authors       = ["Kohei Yamamoto"]
  spec.email         = ["kymmt90@gmail.com"]

  spec.summary       = %q{Bookmeter scraping library}
  spec.description   = %q{Bookmeter scraping library}
  spec.homepage      = "https://github.com/kymmt90/bookmeter_scraper"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "webmock", "~> 1.22"

  spec.add_dependency "yasuri", "~> 0.0"
  spec.add_dependency "mechanize", "~> 2.7"
end
