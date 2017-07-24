# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "dropbox_image_imports"
  spec.version       = '0.0.3'
  spec.authors       = ["Jonny Dalgleish"]
  spec.email         = ["fighella@gmail.com"]

  spec.summary       = %q{ Shopify Product Imports }
  spec.homepage      = "http://git.30acres.com.au"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "shopify_api"
  spec.add_runtime_dependency "fastimage"
  spec.add_runtime_dependency "dropbox-sdk"
  spec.add_runtime_dependency "slack-notifier"
end
