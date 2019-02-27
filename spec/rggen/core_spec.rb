# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RgGen::Core do
  it 'has a version number' do
    expect(RgGen::Core::VERSION).not_to be nil
  end
end
