# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::RegisterMap
  describe ComponentFactory do
    def define_feature(feature_name)
      Class.new(Feature) do
        property feature_name
        build { |v| instance_variable_set(feature_name.variablize, v) }
      end
    end

    let(:bit_field_foo_feature) { define_feature(:foo) }
    let(:bit_field_foo_feature_factory) { FeatureFactory.new(:foo) { |f| f.target_feature(bit_field_foo_feature) } }

    let(:bit_field_bar_feature) { define_feature(:bar) }
    let(:bit_field_bar_feature_factory) { FeatureFactory.new(:bar) { |f| f.target_feature(bit_field_bar_feature) } }

    let(:bit_field_feature_factories) do
      { foo: bit_field_foo_feature_factory, bar: bit_field_bar_feature_factory }
    end

    let(:bit_field_component_factory) do
      ComponentFactory.new do |f|
        f.target_component Component
        f.feature_factories bit_field_feature_factories
      end
    end

    let(:register_foo_feature) { define_feature(:foo) }
    let(:register_foo_feature_factory) { FeatureFactory.new(:foo) { |f| f.target_feature(register_foo_feature) } }

    let(:register_bar_feature) { define_feature(:bar) }
    let(:register_bar_feature_factory) { FeatureFactory.new(:bar) { |f| f.target_feature(register_bar_feature) } }

    let(:register_feature_factories) do
      { foo: register_foo_feature_factory, bar: register_bar_feature_factory }
    end

    let(:register_component_factory) do
      ComponentFactory.new do |f|
        f.target_component Component
        f.feature_factories register_feature_factories
        f.child_factory bit_field_component_factory
      end
    end

    let(:block_foo_feature) { define_feature(:foo) }
    let(:block_foo_feature_factory) { FeatureFactory.new(:foo) { |f| f.target_feature(block_foo_feature) } }

    let(:block_bar_feature) { define_feature(:bar) }
    let(:block_bar_feature_factory) { FeatureFactory.new(:bar) { |f| f.target_feature(block_bar_feature) } }

    let(:block_feature_factories) do
      { foo: block_foo_feature_factory, bar: block_bar_feature_factory }
    end

    let(:block_component_factory) do
      ComponentFactory.new do |f|
        f.target_component Component
        f.feature_factories block_feature_factories
        f.child_factory register_component_factory
      end
    end

    let(:register_map_component_factory) do
      ComponentFactory.new do |f|
        f.target_component Component
        f.feature_factories Hash.new
        f.child_factory block_component_factory
        f.root_factory
        f.loaders [JSONLoader]
      end
    end

    describe "#create" do
      let(:feature_values) do
        {
          register_blocks:  [
            {
              foo:  rand(99),
              bar:  rand(99),
              registers:  [
                {
                  foo:  rand(99),
                  bar:  rand(99),
                  bit_fields: [
                    { foo: rand(99), bar: rand(99) },
                    { foo: rand(99), bar: rand(99) }
                  ]
                },
                {
                  foo:  rand(99),
                  bar:  rand(99),
                  bit_fields: [
                    { foo: rand(99), bar: rand(99) }
                  ]
                }
              ]
            },
            {
              foo:  rand(99),
              registers: [
                {
                  foo:  rand(99),
                  bit_fields: [
                    { foo: rand(99), bar: rand(99) },
                    {                bar: rand(99) }
                  ]
                }
              ]
            }
          ]
        }
      end

      let(:file_contents) { JSON.dump(feature_values) }

      let(:file) { 'foo.json' }

      let(:configuration) { RgGen::Core::Configuration::Component.new }

      before do
        allow(File).to receive(:readable?).with(file).and_return(true)
        allow(File).to receive(:binread).with(file).and_return(file_contents)
      end

      it "レジスタマップコンポーネントの生成と組み立てを行う" do
        register_map = register_map_component_factory.create(configuration, [file])

        expect(register_map.register_blocks[0]).to have_properties({
          foo: feature_values[:register_blocks][0][:foo],
          bar: feature_values[:register_blocks][0][:bar]
        })
        expect(register_map.register_blocks[1]).to have_properties({
          foo: feature_values[:register_blocks][1][:foo],
          bar: feature_values[:register_blocks][1][:bar]
        })

        expect(register_map.registers[0]).to have_properties({
          foo: feature_values[:register_blocks][0][:registers][0][:foo],
          bar: feature_values[:register_blocks][0][:registers][0][:bar]
        })
        expect(register_map.registers[1]).to have_properties({
          foo: feature_values[:register_blocks][0][:registers][1][:foo],
          bar: feature_values[:register_blocks][0][:registers][1][:bar]
        })
        expect(register_map.registers[2]).to have_properties({
          foo: feature_values[:register_blocks][1][:registers][0][:foo],
          bar: feature_values[:register_blocks][1][:registers][0][:bar]
        })

        expect(register_map.bit_fields[0]).to have_properties({
          foo: feature_values[:register_blocks][0][:registers][0][:bit_fields][0][:foo],
          bar: feature_values[:register_blocks][0][:registers][0][:bit_fields][0][:bar]
        })
        expect(register_map.bit_fields[1]).to have_properties({
          foo: feature_values[:register_blocks][0][:registers][0][:bit_fields][1][:foo],
          bar: feature_values[:register_blocks][0][:registers][0][:bit_fields][1][:bar]
        })
        expect(register_map.bit_fields[2]).to have_properties({
          foo: feature_values[:register_blocks][0][:registers][1][:bit_fields][0][:foo],
          bar: feature_values[:register_blocks][0][:registers][1][:bit_fields][0][:bar]
        })
        expect(register_map.bit_fields[3]).to have_properties({
          foo: feature_values[:register_blocks][1][:registers][0][:bit_fields][0][:foo],
          bar: feature_values[:register_blocks][1][:registers][0][:bit_fields][0][:bar]
        })
        expect(register_map.bit_fields[4]).to have_properties({
          foo: feature_values[:register_blocks][1][:registers][0][:bit_fields][1][:foo],
          bar: feature_values[:register_blocks][1][:registers][0][:bit_fields][1][:bar]
        })
      end
    end
  end
end
