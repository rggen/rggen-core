require 'spec_helper'

module RgGen::Core::InputBase
  describe InputError do
    describe "#to_s" do
      let(:message) { 'input error!' }

      let(:position) { Struct.new(:x, :y).new(0, 1) }

      context "位置情報が与えられなかった場合" do
        it "エラーメッセージのみを表示する" do
          error = InputError.new(message)
          expect(error.to_s).to eq message
        end
      end

      context "位置情報が与えられた場合" do
        it "エラーメッセージを、位置情報込で、表示する" do
          error = InputError.new(message, position)
          expect(error.to_s).to eq "#{message} -- #{position}"
        end
      end
    end
  end
end
