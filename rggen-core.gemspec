# frozen_string_literal: true

require File.expand_path('lib/rggen/core/version', __dir__)

Gem::Specification.new do |spec|
  spec.name = 'rggen-core'
  spec.version = RgGen::Core::VERSION
  spec.authors = ['Taichi Ishitani']
  spec.email = ['rggen@googlegroups.com']

  spec.summary = "rggen-core-#{RgGen::Core::VERSION}"
  spec.description = 'Core library of RgGen tool.'
  spec.homepage = 'https://github.com/rggen/rggen-core'
  spec.license = 'MIT'

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/rggen/rggen/issues',
    'mailing_list_uri' => 'https://groups.google.com/d/forum/rggen',
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => 'https://github.com/rggen/rggen-core',
    'wiki_uri' => 'https://github.com/rggen/rggen/wiki'
  }

  spec.files = `git ls-files exe lib LICENSE CODE_OF_CONDUCT.md README.md`.split($RS)
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.6'

  spec.add_runtime_dependency 'docile', '>= 1.1.5', '!= 1.3.3'
  spec.add_runtime_dependency 'erubi', '>= 1.7'
  spec.add_runtime_dependency 'facets', '>= 3.0'
  spec.add_runtime_dependency 'tomlrb', '>= 2.0'

  spec.add_development_dependency 'bundler'
end
