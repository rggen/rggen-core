# frozen_string_literal: true

RSpec.describe RgGen::Core::RegisterMap::RaiseError do
  let(:register_map_error) do
    RgGen::Core::RegisterMap::RegisterMapError
  end

  let(:object) do
    klass = Class.new do
      include RgGen::Core::RegisterMap::RaiseError
    end
    klass.new
  end

  describe '#error_exception' do
    it 'RegisterMapErrorを返す' do
      expect(object.send(:error_exception)).to equal register_map_error
    end
  end
end
