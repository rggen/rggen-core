# frozen_string_literal: true

require 'bundler/setup'
require 'rggen/devtools/spec_helper'

RSpec.configure do |config|
  RgGen::Devtools::SpecHelper.setup(
    config, coverage_filter: /forwardable_workaround/
  )
  config.before(:each) do
    allow(FileUtils).to receive(:mkpath)
  end
end

require 'rggen/core'
