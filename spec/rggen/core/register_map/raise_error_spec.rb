# frozen_string_literal: true

RSpec.describe RgGen::Core::RegisterMap::RaiseError do
  describe '#error' do
    let(:message) { 'register map error !' }

    let(:positions) { [Struct.new(:x, :y).new(0, 1), Struct.new(:x, :y).new(2, 3)]}

    let(:register_map_error) do
      RgGen::Core::RegisterMap::RegisterMapError
    end

    let(:object) do
      Class.new do
        include RgGen::Core::RegisterMap::RaiseError
        attr_writer :position
        def error_test(message, position = nil)
          if position
            error message, position
          else
            error message
          end
        end
      end.new
    end

    context '位置情報がない場合' do
      it '与えられたメッセージで、RegisterMapError を発生させる' do
        expect {
          object.error_test(message)
        }.to raise_rggen_error register_map_error, message
      end
    end

    context 'エラーの発生元が位置情報を持つ場合' do
      it '位置情報と与えられたメッセージで、RegisterMapError を発生させる' do
        object.position = positions[0]
        expect {
          object.error_test(message)
        }.to raise_rggen_error register_map_error, message, positions[0]
      end
    end

    context '位置情報が与えられた場合' do
      it '与えられた位置情報とメッセージで、RegisterMapError を発生させる' do
        expect {
          object.error_test(message, positions[1])
        }.to raise_rggen_error register_map_error, message, positions[1]

        object.position = positions[0]
        expect {
          object.error_test(message, positions[1])
        }.to raise_rggen_error register_map_error, message, positions[1]
      end
    end
  end
end
