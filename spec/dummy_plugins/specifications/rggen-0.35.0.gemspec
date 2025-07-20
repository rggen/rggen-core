# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'rggen'
  spec.version = RgGen::Core::VERSION
  spec.authors = ['Taichi Ishitani']
  spec.summary = 'RgGen dummy plugin'
  spec.require_paths = ['lib']
  spec.add_runtime_dependency 'rggen-core', "~> #{RgGen::Core::VERSION}"
end
