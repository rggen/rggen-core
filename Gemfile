# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in rggen-core.gemspec
gemspec

if ENV['USE_FIXED_GEMS']
  ['facets'].each do |library|
    library_path = File.expand_path("../#{library}", __dir__)
    if Dir.exist?(library_path) && !ENV['USE_GITHUB_REPOSITORY']
      gem library, path: library_path
    else
      gem library, git: "https://github.com/taichi-ishitani/#{library}.git"
    end
  end
end

group :develop do
  gem 'rake'
  gem 'rspec', '>= 3.3'
  gem 'codecov', require: false
  gem 'rubocop', '>= 0.48.0', require: false
end
