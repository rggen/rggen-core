# frozen_string_literal: true

require_relative 'lib/rggen/foo/version'

Gem::Specification.new do |spec|
  spec.name = 'rggen-foo'
  spec.version = RgGen::Foo::VERSION
  spec.authors = ['Taichi Ishitani']
  spec.summary = 'RgGen dummy plugin'

  spec.files  = [
    'lib/rggen/foo/version.rb',
    'lib/rggen/foo/setup.rb',
    'lib/rggen/foo/bar/setup.rb',
    'lib/rggen/foo/bar/baz/setup.rb',
    'lib/rggen/foo/bar_baz/setup.rb'
  ]

  spec.require_paths = ['lib']
end
