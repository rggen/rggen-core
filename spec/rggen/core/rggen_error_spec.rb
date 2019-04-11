# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core
  describe RgGenError do
    let(:message) { 'error !' }

    let(:additional_info) { Struct.new(:x, :y).new(0, 1) }

    context '追加情報がある場合' do
      it '追加情報込でエラーメッセージを表示する' do
        expect {
          raise RgGenError.new(message, additional_info)
        }.to raise_error RgGenError, "#{message} -- #{additional_info}"
      end
    end

    context '追加情報がない場合' do
      it 'エラーメッセージのみを表示する' do
        expect {
          raise RgGenError.new(message)
        }.to raise_error RgGenError, message
      end
    end
  end
end
