# frozen_string_literal: true

RSpec.describe RgGen::Core::OutputBase::DocumentComponentFactory do
  let(:configuration) do
    RgGen::Core::Configuration::Component.new(nil, :configuration, nil)
  end

  def create_register_map(parent, layer, document)
    RgGen::Core::RegisterMap::Component.new(parent, :register_map, layer, configuration) do |c|
      document && c.document_only
      parent&.add_child(c)
    end
  end

  def create_factory(layer, factories)
    factory = described_class.new('component', layer) do |f|
      f.target_component RgGen::Core::OutputBase::Component
      f.component_factories factories
      f.root_factory if layer == :root
    end
    factories[layer] = factory
  end

  let!(:root) do
    create_register_map(nil, :root, false)
  end

  let!(:register_blocks) do
    [
      create_register_map(root, :register_block, false),
      create_register_map(root, :register_block, true)
    ]
  end

  let!(:registers) do
    [
      create_register_map(register_blocks[0], :register, false),
      create_register_map(register_blocks[0], :register, true),
      create_register_map(register_blocks[1], :register, false),
      create_register_map(register_blocks[1], :register, true)
    ]
  end

  let(:factory) do
    factories = {}
    [:root, :register_block, :register].each do |layer|
      create_factory(layer, factories)
    end
    factories[:root]
  end

  it 'ドキュメント用かに関係なく、全コンポーネントを生成する' do
    root_component = factory.create(configuration, root)
    expect(root_component.register_blocks.size).to eq 2
    expect(root_component.registers.size).to eq 4
  end
end
