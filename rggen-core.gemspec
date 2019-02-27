# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.include?(lib) || $LOAD_PATH.unshift(lib)
require 'rggen/core/version'

Gem::Specification.new do |spec|
  spec.name = 'rggen-core'
  spec.version = RgGen::Core::VERSION
  spec.authors = ['Taichi Ishitani']
  spec.email = ['taichi730@gmail.com']
  spec.license = 'MIT'
  spec.homepage = 'https://github.com/rggen/rggen-core'

  spec.summary = "rggen-core-#{RgGen::Core::VERSION}"
  spec.description = 'Core components for RgGen tool.'

  spec.files = `git ls-files exe lib LICENSE README.md`.split($RS)
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3'

  spec.add_runtime_dependency 'docile', '>= 1.1.5'
  spec.add_runtime_dependency 'erubi', '>= 1.7'
  spec.add_runtime_dependency 'facets', '>= 3.0'

  spec.add_development_dependency 'bundler'
end
