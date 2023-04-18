# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::ConversionUtility do
  let(:position) do
    Struct.new(:x, :y).new(1, 2)
  end

  let(:exception) do
    RgGen::Core::RuntimeError
  end

  let(:object) do
    klass = Class.new do
      include RgGen::Core::InputBase::Error
      include RgGen::Core::InputBase::ConversionUtility

      def initialize(error_exception)
        @error_exception = error_exception
      end

      attr_reader :error_exception
    end
    klass.new(exception)
  end

  def input_value(value)
    RgGen::Core::InputBase::InputValue.new(value, position)
  end

  describe '#to_int' do
    def to_int(*argv, &b)
      object.__send__(:to_int, *argv, &b)
    end

    it '引数を整数に変換する' do
      expect(to_int(4)).to eq 4
      expect(to_int(input_value(4))).to eq 4

      expect(to_int(9.88)).to eq 9
      expect(to_int(input_value(9.88))).to eq 9

      expect(to_int('10')).to eq 10
      expect(to_int(input_value('10'))).to eq 10

      expect(to_int('0d10')).to eq 10
      expect(to_int(input_value('0d10'))).to eq 10

      expect(to_int('010')).to eq 8
      expect(to_int(input_value('010'))).to eq 8

      expect(to_int('0o10')).to eq 8
      expect(to_int(input_value('0o10'))).to eq 8

      expect(to_int('0x10')).to eq 16
      expect(to_int(input_value('0x10'))).to eq 16

      expect(to_int('0b10')).to eq 2
      expect(to_int(input_value('0b10'))).to eq 2
    end

    context '整数に変換できない場合' do
      it '#errorを用いて例外を上げる' do
        block = proc do |v|
          "cannot convert #{v.inspect} into integer"
        end

        [nil, true, false, '', 'foo', '0x1gh', :foo, Object.new].each do |value|
          expect {
            to_int(value, position, &block)
          }.to raise_error exception, "cannot convert #{value.inspect} into integer -- #{position}"

          expect {
            to_int(input_value(value), &block)
          }.to raise_error exception, "cannot convert #{value.inspect} into integer -- #{position}"
        end
      end
    end
  end
end
