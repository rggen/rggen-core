# frozen_string_literal: true

require 'bundler/setup'
require 'rggen/devtools/spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.configure do |config|
  RgGen::Devtools::SpecHelper.setup(config)
  config.before(:each) do
    allow(FileUtils).to receive(:mkpath)
  end
end

require 'rggen/core'

RGGEN_CORE_ROOT = File.expand_path('..', __dir__)
