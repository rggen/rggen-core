# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::InputBase
  ::RSpec.describe Verifier do
    describe '#verify' do
      let(:feature) { Object.new }

      let(:verifier) do
        block = proc do
          error_condition { foo }
          message { bar }
        end
        Verifier.new(block)
      end

      it '#error_conditionで与えたブロックを、フィーチャー上で評価する' do
        expect(feature).to receive(:foo).and_return(false)
        verifier.verify(feature)
      end

      context '#error_conditionの評価結果が真の場合' do
        let(:message) { 'error !' }

        it '#messageで与えたブロックを、フィーチャー上で評価し、エラーメッセージとする' do
          expect(feature).to receive(:foo).and_return(true)
          expect(feature).to receive(:bar).and_return(message)
          expect(feature).to receive(:error).with(message)
          verifier.verify(feature)
        end
      end
    end
  end
end
