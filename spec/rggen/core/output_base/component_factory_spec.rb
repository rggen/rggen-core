# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::OutputBase
  describe ComponentFactory do
    let(:configuration) do
      RgGen::Core::Configuration::Component.new(nil)
    end

    def create_register_map(parent)
      RgGen::Core::RegisterMap::Component.new(parent, configuration) do |c|
        parent&.add_child(c)
      end
    end

    let(:register_map) do
      create_register_map(nil)
    end

    let(:register_blocks) do
      Array.new(2) { create_register_map(register_map) }
    end

    let(:registers) do
      register_blocks.flat_map do |register_block|
        Array.new(2) { create_register_map(register_block) }
      end
    end

    let(:bit_fields) do
      registers.flat_map do |register|
        Array.new(2) { create_register_map(register) }
      end
    end

    def define_feature(hierarchy, name)
      Class.new(Feature) do
        export "feature_#{name}"
        define_method("feature_#{name}") do
          @value
        end
        build do
          @value = "#{send(hierarchy).object_id} #{send(hierarchy).send(name)}"
        end
      end
    end

    def create_feature_factory(hierarchy, name)
      feature = define_feature(hierarchy, name)
      FeatureFactory.new(name) do |f|
        f.target_feature feature
      end
    end

    def create_component_factory(hierarchy, child_factory)
      feature_factories =
        if hierarchy != :register_map
          {
            fizz: create_feature_factory(hierarchy, :fizz),
            buzz: create_feature_factory(hierarchy, :buzz)
          }
        end
      ComponentFactory.new do |f|
        f.target_component Component
        f.feature_factories feature_factories
        f.child_factory child_factory
        f.root_factory if hierarchy == :register_map
      end
    end

    let(:bit_field_component_factory) do
      create_component_factory(:bit_field, nil)
    end

    let(:register_component_facotry) do
      create_component_factory(:register, bit_field_component_factory)
    end

    let(:register_block_component_factory) do
      create_component_factory(:register_block, register_component_facotry)
    end

    let(:register_map_component_factory) do
      create_component_factory(:register_map, register_block_component_factory)
    end

    before do
      [*register_blocks, *registers, *bit_fields].each_with_index do |component, i|
        allow(component).to receive(:properties).and_return([:fizz, :buzz])
        allow(component).to receive(:fizz).and_return("fizz #{"!" * (i + 1)}")
        allow(component).to receive(:buzz).and_return("buzz #{"!" * (i + 1)}")
      end
    end

    describe "#create" do
      it "出力コンポーネントの生成と組み立てを行う" do
        output_component = register_map_component_factory.create(configuration, register_map)

        register_blocks.each_with_index do |register_block, i|
          expect(output_component.register_blocks[i].feature_fizz).to eq "#{output_component.register_blocks[i].object_id} #{register_block.fizz}"
          expect(output_component.register_blocks[i].feature_buzz).to eq "#{output_component.register_blocks[i].object_id} #{register_block.buzz}"
        end

        registers.each_with_index do |register, i|
          expect(output_component.registers[i].feature_fizz).to eq "#{output_component.registers[i].object_id} #{register.fizz}"
          expect(output_component.registers[i].feature_buzz).to eq "#{output_component.registers[i].object_id} #{register.buzz}"
        end

        bit_fields.each_with_index do |bit_field, i|
          expect(output_component.bit_fields[i].feature_fizz).to eq "#{output_component.bit_fields[i].object_id} #{bit_field.fizz}"
          expect(output_component.bit_fields[i].feature_buzz).to eq "#{output_component.bit_fields[i].object_id} #{bit_field.buzz}"
        end
      end
    end
  end
end
