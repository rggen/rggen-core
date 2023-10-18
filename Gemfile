# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in rggen-core.gemspec
gemspec

root = ENV['RGGEN_ROOT'] || File.expand_path('..', __dir__)
gemfile = File.join(root, 'rggen-devtools', 'gemfile', 'common.gemfile')
eval_gemfile(gemfile)

group :rggen do
  gem_patched 'facets'
end

group :test do
  ['rggen', 'rggen-foo', 'rggen-foo-bar']
    .map { |plugin| [plugin, File.join(__dir__, 'spec', 'dummy_plugins', plugin)] }
    .each { |(plugin, path)| gem plugin, path: path }
end
