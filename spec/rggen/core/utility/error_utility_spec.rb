# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RgGen::Core::Utility::ErrorUtility do
  let(:utility) { RgGen::Core::Utility::ErrorUtility }

  describe '#compose_error_message' do
    let(:error) do
      begin
        1 / 0
      rescue StandardError => e
        e
      end
    end

    context 'verboseにfalseが指定されている場合' do
      it 'エラーメッセージのみ表示する' do
        message = utility.compose_error_message(error, false)
        expect(message).to eq '[ZeroDivisionError] divided by 0'
      end
    end

    context 'verboseにfalseが指定されている場合' do
      it 'エラーメッセージとバックトレースを表示する' do
        message = utility.compose_error_message(error, true)
        expect(message).to eq [
          '[ZeroDivisionError] divided by 0',
          *error.backtrace.map { |trace| "    #{trace}" }
        ].join("\n")
      end
    end
  end
end
