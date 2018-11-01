if ENV['TRAVIS']
  require 'simplecov'
  SimpleCov.start
end

require 'bundler/setup'
require 'rggen/core'
require 'rggen/core/spec_helpers'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.before(:each) do
    allow(FileUtils).to receive(:mkpath)
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
