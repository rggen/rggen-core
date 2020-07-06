# frozen_string_literal: true

RSpec.describe RgGen::Core::OutputBase::ComponentFactory do
  let(:configuration) do
    RgGen::Core::Configuration::Component.new(nil, :configuration, nil)
  end

  def create_register_map(parent, layer)
    RgGen::Core::RegisterMap::Component.new(parent, :register_map, layer, configuration) do |c|
      parent&.add_child(c)
    end
  end

  let(:root) do
    create_register_map(nil, :root)
  end

  let(:register_blocks) do
    [
      create_register_map(root, :register_block),
      create_register_map(root, :register_block)
    ]
  end

  let(:register_files) do
    [
      create_register_map(register_blocks[1], :register_file),
      create_register_map(register_blocks[1], :register_file),
      create_register_map(register_blocks[1].children[0], :register_file)
    ]
  end

  let(:registers) do
    [
      create_register_map(register_blocks[0], :register),
      create_register_map(register_blocks[0], :register),
      create_register_map(register_files[0], :register),
      create_register_map(register_files[1], :register),
      create_register_map(register_files[1], :register),
      create_register_map(register_files[2], :register),
      create_register_map(register_files[2], :register),
    ]
  end

  let(:bit_fields) do
    registers.flat_map do |register|
      Array.new(2) { create_register_map(register, :bit_field) }
    end
  end

  def define_feature(layer, name)
    Class.new(RgGen::Core::OutputBase::Feature) do
      export "feature_#{name}"
      define_method("feature_#{name}") do
        @value
      end
      build do
        @value = "#{send(layer).object_id} #{send(layer).send(name)}"
      end
    end
  end

  def create_feature_factory(layer, name)
    feature = define_feature(layer, name)
    RgGen::Core::OutputBase::FeatureFactory.new(name) do |f|
      f.target_feature feature
    end
  end

  def create_component_factory(factories, layer)
    feature_factories =
      if layer != :root
        {
          fizz: create_feature_factory(layer, :fizz),
          buzz: create_feature_factory(layer, :buzz)
        }
      end
    factories[layer] = described_class.new('component', layer) do |f|
      f.target_component RgGen::Core::OutputBase::Component
      f.component_factories factories
      f.feature_factories feature_factories
      f.root_factory if layer == :root
    end
  end

  let!(:component_factories) { {} }

  let!(:bit_field_component_factory) do
    create_component_factory(component_factories, :bit_field)
  end

  let!(:register_component_facotry) do
    create_component_factory(component_factories, :register)
  end

  let!(:register_file_component_factory) do
    create_component_factory(component_factories, :register_file)
  end

  let!(:register_block_component_factory) do
    create_component_factory(component_factories, :register_block)
  end

  let!(:root_component_factory) do
    create_component_factory(component_factories, :root)
  end

  before do
    [*register_blocks, *register_files, *registers, *bit_fields].each.with_index(1) do |c, i|
      allow(c).to receive(:properties).and_return([:fizz, :buzz])
      allow(c).to receive(:fizz).and_return("fizz #{'!' * i}")
      allow(c).to receive(:buzz).and_return("buzz #{'!' * i}")
    end
  end

  describe '#create' do
    it '出力コンポーネントの生成と組み立てを行う' do
      output_root = root_component_factory.create(configuration, root)

      output_register_blocks = [
        output_root.register_blocks[0],
        output_root.register_blocks[1]
      ]
      output_register_blocks.each_with_index do |block, i|
        expect(block.feature_fizz).to eq "#{block.object_id} #{register_blocks[i].fizz}"
        expect(block.feature_buzz).to eq "#{block.object_id} #{register_blocks[i].buzz}"
      end

      output_register_files = [
        output_register_blocks[1].files_and_registers[0],
        output_register_blocks[1].files_and_registers[1],
        output_register_blocks[1].files_and_registers[0].files_and_registers[0]
      ]
      output_register_files.each_with_index do |file, i|
        expect(file.feature_fizz).to eq "#{file.object_id} #{register_files[i].fizz}"
        expect(file.feature_buzz).to eq "#{file.object_id} #{register_files[i].buzz}"
      end

      output_registers = [
        output_register_blocks[0].files_and_registers[0],
        output_register_blocks[0].files_and_registers[1],
        output_register_files[0].files_and_registers[1],
        output_register_files[1].files_and_registers[0],
        output_register_files[1].files_and_registers[1],
        output_register_files[2].files_and_registers[0],
        output_register_files[2].files_and_registers[1]
      ]
      output_registers.each_with_index do |register, i|
        expect(register.feature_fizz).to eq "#{register.object_id} #{registers[i].fizz}"
        expect(register.feature_buzz).to eq "#{register.object_id} #{registers[i].buzz}"
      end

      output_bit_fiels = output_registers.flat_map(&:bit_fields)
      output_bit_fiels.each_with_index do |bit_field, i|
        expect(bit_field.feature_fizz).to eq "#{bit_field.object_id} #{bit_fields[i].fizz}"
        expect(bit_field.feature_buzz).to eq "#{bit_field.object_id} #{bit_fields[i].buzz}"
      end
    end
  end
end
