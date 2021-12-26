# frozen_string_literal: true

require_relative 'lib/rggen/foo_bar/version'

Gem::Specification.new do |spec|
  spec.name = 'rggen-foo-bar'
  spec.version = RgGen::FooBar::VERSION
  spec.authors = ['Taichi Ishitani']
  spec.summary = 'RgGen dummy plugin'

  spec.files  = [
    'lib/rggen/foo_bar/version.rb',
    'lib/rggen/foo_bar/setup.rb',
    'lib/rggen/foo_bar/baz/setup.rb'
  ]

  spec.require_paths = ['lib']
end
