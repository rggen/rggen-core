# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::Verifier do
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
      it 'フィーチャー上でブロックを実行し、エラーの確認を行う' do
        verifier = described_class.new { check_error { error 'error!' } }
        expect { verifier.verify(feature) }.to raise_error 'error!'

        verifier = described_class.new { check_error { |v| error "#{v} error!" } }
        expect { verifier.verify(feature, 'foo') }.to raise_error 'foo error!'
      end
    end

    context '#error_condition/#messageでエラー条件とエラーメッセージが指定された場合' do
      it '#error_conditionで与えたブロックを、フィーチャー上で評価する' do
        expect(feature).to receive(:foo).and_return(false)
        verifier = described_class.new { error_condition { foo } }
        verifier.verify(feature)

        expect(feature).to receive(:bar).with(:bar).and_return(false)
        verifier = described_class.new { error_condition { |v| bar(v) } }
        verifier.verify(feature, :bar)
      end

      context '#error_conditionの評価結果が真の場合' do
        it '#messageで与えたブロックを、フィーチャー上で評価し、エラーメッセージとする' do
          allow(feature).to receive(:foo).and_return('error!')
          verifier = described_class.new { error_condition { true }; message { foo } }
          expect { verifier.verify(feature) }.to raise_error 'error!'

          allow(feature).to receive(:bar).and_return('error!')
          verifier = described_class.new { error_condition { true }; message { |v| "#{v} #{bar}" } }
          expect { verifier.verify(feature, 'bar') }.to raise_error 'bar error!'
        end
      end
    end
  end
end
