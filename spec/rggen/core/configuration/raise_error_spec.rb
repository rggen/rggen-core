require 'spec_helper'

module RgGen::Core::Configuration
  describe RaiseError do
    describe "#error" do
      let(:message) { 'configuration error !' }

      let(:object) do
        Class.new do
          include RaiseError
          def error_test(message)
            error message
          end
        end.new
      end

      it "与えられたメッセージで、ConfigurationErrorを発生させる" do
        expect {
          object.error_test(message)
        }.to raise_error RgGen::Core::Configuration::ConfigurationError, message
      end
    end
  end
end
