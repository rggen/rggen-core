# frozen_string_literal: true

require_relative 'lib/rggen/version'

Gem::Specification.new do |spec|
  spec.name = 'rggen'
  spec.version = RgGen::VERSION
  spec.authors = ['Taichi Ishitani']
  spec.summary = 'RgGen dummy plugin'

  spec.files  = [
    'lib/rggen/version.rb',
    'lib/rggen/default.rb'
  ]

  spec.require_paths = ['lib']
  spec.add_runtime_dependency 'rggen-core', "~> #{RgGen::Core::VERSION}"
end
