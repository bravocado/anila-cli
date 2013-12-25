# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'anila/cli/version'

Gem::Specification.new do |spec|
  spec.name          = "anila"
  spec.version       = Anila::Cli::VERSION
  spec.authors       = ["Bravocado"]
  spec.email         = ["bravocado.project@gmail.com"]
  spec.description   = %q{A CLI for working with Anila}
  spec.summary       = %q{Easy starting a project with Anila}
  spec.homepage      = "http://github.com/bravocado/anila-cli.git"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_dependency "thor", [">= 0.18.1"]
end
