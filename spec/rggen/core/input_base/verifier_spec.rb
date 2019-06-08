# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::InputBase
  ::RSpec.describe Verifier do
    describe '#verify' do
      let(:feature) do
        klass = Class.new do
          def error(message)
            raise message
          end
        end
        klass.new
      end

      context '#check_errorでブロックが与えられた場合' do
        let(:verifier) do
          Verifier.new do
            check_error { error 'error !' }
          end
        end

        it 'フィーチャー上でブロックを実行し、エラーの確認を行う' do
          expect { verifier.verify(feature) }.to raise_error 'error !'
        end
      end

      context '#error_condition/#messageでエラー条件とエラーメッセージが指定された場合' do
        let(:verifier) do
          Verifier.new do
            error_condition { foo }
            message { bar }
          end
        end

        it '#error_conditionで与えたブロックを、フィーチャー上で評価する' do
          expect(feature).to receive(:foo).and_return(false)
          verifier.verify(feature)
        end

        context '#error_conditionの評価結果が真の場合' do
          it '#messageで与えたブロックを、フィーチャー上で評価し、エラーメッセージとする' do
            expect(feature).to receive(:foo).and_return(true)
            expect(feature).to receive(:bar).and_return('error !')

            expect { verifier.verify(feature) }.to raise_error 'error !'
          end
        end
      end
    end
  end
end
