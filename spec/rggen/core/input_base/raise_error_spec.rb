# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::RaiseError do
  let(:message) do
    'error !'
  end

  let(:position) do
    Struct.new(:x, :y).new(1, 2)
  end

  let(:exception) do
    RgGen::Core::RuntimeError
  end

  let(:object) do
    klass = Class.new do
      include RgGen::Core::InputBase::RaiseError

      def initialize(exception)
        @error_exception = exception
      end

      attr_reader :error_exception
      attr_writer :position

      def error_test(*argv)
        error *argv
      end
    end
    klass.new(exception)
  end

  def input_value(position)
    RgGen::Core::InputBase::InputValue.new(0, position)
  end

  describe '#error' do
    it '与えられたメッセージ、位置情報で例外を上げる' do
      expect {
        object.error_test(message, input_value(position))
      }.to raise_error exception, "#{message} -- #{position}"

      expect {
        object.error_test(message, position)
      }.to raise_error exception, "#{message} -- #{position}"
    end

    context '位置情報が与えられず' do
      context '#error_positionを持つ場合' do
        specify '#error_positionを位置情報とする' do
          expect(object).to receive(:error_position).and_return(position)
          expect {
            object.error_test(message, input_value(nil))
          }.to raise_error exception, "#{message} -- #{position}"

          expect(object).to receive(:error_position).and_return(position)
          expect {
            object.error_test(message, nil)
          }.to raise_error exception, "#{message} -- #{position}"

          expect(object).to receive(:error_position).and_return(position)
          expect {
            object.error_test(message)
          }.to raise_error exception, "#{message} -- #{position}"
        end
      end

      context 'インスタンス変数@positionを持つ場合' do
        specify '@positionを位置情報とする' do
          object.position = position

          expect {
            object.error_test(message, input_value(nil))
          }.to raise_error exception, "#{message} -- #{position}"

          expect {
            object.error_test(message, nil)
          }.to raise_error exception, "#{message} -- #{position}"

          expect {
            object.error_test(message)
          }.to raise_error exception, "#{message} -- #{position}"
        end
      end
    end

    context '位置情報を取得できない場合' do
      it '位置情報なしで例外を上げる' do
        expect {
          object.error_test(message, input_value(nil))
        }.to raise_error exception, message

        expect {
          object.error_test(message, nil)
        }.to raise_error exception, message

        expect {
          object.error_test(message)
        }.to raise_error exception, message
      end
    end
  end
end
