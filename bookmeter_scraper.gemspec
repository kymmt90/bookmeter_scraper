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

  spec.required_ruby_version = '>= 2.0'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "yard"

  spec.add_dependency "mechanize"
  spec.add_dependency "yasuri"
end
