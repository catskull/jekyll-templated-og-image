Gem::Specification.new do |spec|
  spec.name          = "jekyll-og-image"
  spec.version       = "0.1.0"
  spec.authors       = ["dwd"]
  spec.summary       = "Generate Open Graph images for Jekyll pages and posts"
  spec.homepage      = "https://github.com/catskull/jekyll-og-image"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0"

  spec.add_dependency "jekyll", ">= 4.0"
  spec.add_dependency "ferrum", "~> 0.15"
end
