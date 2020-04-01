# frozen_string_literal: true

RSpec.describe RgGen::Core::RegisterMap::ComponentFactory do
  def define_feature(feature_name)
    Class.new(RgGen::Core::RegisterMap::Feature) do
      property feature_name
      build { |v| instance_variable_set("@#{feature_name}", v) }
    end
  end

  def create_feature_factory(feature_name, feature_class)
    RgGen::Core::RegisterMap::FeatureFactory.new(feature_name) do |f|
      f.target_feature(feature_class)
    end
  end

  let(:component_factories) { {} }

  let(:bit_field_foo_feature) { define_feature(:foo) }
  let(:bit_field_foo_feature_factory) { create_feature_factory(:foo, bit_field_foo_feature) }

  let(:bit_field_bar_feature) { define_feature(:bar) }
  let(:bit_field_bar_feature_factory) { create_feature_factory(:bar, bit_field_bar_feature) }

  let(:bit_field_feature_factories) do
    { foo: bit_field_foo_feature_factory, bar: bit_field_bar_feature_factory }
  end

  let!(:bit_field_component_factory) do
    component_factories[:bit_field] =
      described_class.new('register_map', :bit_field) do |f|
        f.target_component RgGen::Core::RegisterMap::Component
        f.component_factories component_factories
        f.feature_factories bit_field_feature_factories
      end
  end

  let(:register_foo_feature) { define_feature(:foo) }
  let(:register_foo_feature_factory) { create_feature_factory(:foo, register_foo_feature) }

  let(:register_bar_feature) { define_feature(:bar) }
  let(:register_bar_feature_factory) { create_feature_factory(:bar, register_bar_feature) }

  let(:register_feature_factories) do
    { foo: register_foo_feature_factory, bar: register_bar_feature_factory }
  end

  let!(:register_component_factory) do
    component_factories[:register] =
      described_class.new('register_map', :register) do |f|
        f.target_component RgGen::Core::RegisterMap::Component
        f.component_factories component_factories
        f.feature_factories register_feature_factories
      end
  end

  let(:file_foo_feature) { define_feature(:foo) }
  let(:file_foo_feature_factory) { create_feature_factory(:foo, file_foo_feature) }

  let(:file_bar_feature) { define_feature(:bar) }
  let(:file_bar_feature_factory) { create_feature_factory(:bar, file_bar_feature) }

  let(:file_feature_factories) do
    { foo: file_foo_feature_factory, bar: file_bar_feature_factory }
  end

  let!(:file_component_factory) do
    component_factories[:register_file] =
      described_class.new('register_map', :register_file) do |f|
        f.target_component RgGen::Core::RegisterMap::Component
        f.component_factories component_factories
        f.feature_factories file_feature_factories
      end
  end

  let(:block_foo_feature) { define_feature(:foo) }
  let(:block_foo_feature_factory) { create_feature_factory(:foo, block_foo_feature) }

  let(:block_bar_feature) { define_feature(:bar) }
  let(:block_bar_feature_factory) { create_feature_factory(:bar, block_bar_feature) }

  let(:block_feature_factories) do
    { foo: block_foo_feature_factory, bar: block_bar_feature_factory }
  end

  let!(:block_component_factory) do
    component_factories[:register_block] =
      described_class.new('register_map', :register_block) do |f|
        f.target_component RgGen::Core::RegisterMap::Component
        f.component_factories component_factories
        f.feature_factories block_feature_factories
      end
  end

  let!(:root_component_factory) do
    component_factories[:root] =
      described_class.new('register_map', :root) do |f|
        f.target_component RgGen::Core::RegisterMap::Component
        f.component_factories component_factories
        f.feature_factories {}
        f.root_factory
        f.loaders [RgGen::Core::RegisterMap::JSONLoader]
      end
  end

  describe '#create' do
    let(:feature_values) do
      {
        register_blocks:  [
          {
            foo:  rand(99),
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
                bar:  rand(99),
                bit_fields: [
                  { foo: rand(99), bar: rand(99) }
                ]
              }
            ]
          },
          {
            foo: rand(99),
            bar: rand(99),
            register_files: [
              {
                foo: rand(99),
                bar: rand(99),
                registers: [
                  foo: rand(99),
                  bar: rand(99),
                  bit_fields: [
                    { foo: rand(99), bar: rand(99) }
                  ]
                ]
              },
              {
                foo: rand(99),
                bar: rand(99),
                registers: [
                  foo: rand(99),
                  bar: rand(99),
                  bit_fields: [
                    { foo: rand(99), bar: rand(99) }
                  ]
                ]
              }
            ],
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

    let(:file_content) { JSON.dump(feature_values) }

    let(:file) { 'foo.json' }

    let(:configuration) { RgGen::Core::Configuration::Component.new(nil, 'configuration', nil) }

    before do
      allow(File).to receive(:readable?).with(file).and_return(true)
      allow(File).to receive(:binread).with(file).and_return(file_content)
    end

    it 'レジスタマップコンポーネントの生成と組み立てを行う' do
      root = root_component_factory.create(configuration, [file])

      register_block = root.register_blocks[0]
      expect(register_block).to have_properties({
        foo: feature_values.dig(:register_blocks, 0, :foo),
        bar: feature_values.dig(:register_blocks, 0, :bar)
      })

      register = register_block.files_and_registers[0]
      expect(register).to have_properties({
        foo: feature_values.dig(:register_blocks, 0, :registers, 0, :foo),
        bar: feature_values.dig(:register_blocks, 0, :registers, 0, :bar)
      })

      bit_field = register.bit_fields[0]
      expect(bit_field).to have_properties({
        foo: feature_values.dig(:register_blocks, 0, :registers, 0, :bit_fields, 0, :foo),
        bar: feature_values.dig(:register_blocks, 0, :registers, 0, :bit_fields, 0, :bar)
      })

      bit_field = register.bit_fields[1]
      expect(bit_field).to have_properties({
        foo: feature_values.dig(:register_blocks, 0, :registers, 0, :bit_fields, 1, :foo),
        bar: feature_values.dig(:register_blocks, 0, :registers, 0, :bit_fields, 1, :bar)
      })

      register = register_block.files_and_registers[1]
      expect(register).to have_properties({
        foo: feature_values.dig(:register_blocks, 0, :registers, 1, :foo),
        bar: feature_values.dig(:register_blocks, 0, :registers, 1, :bar)
      })

      bit_field = register.bit_fields[0]
      expect(bit_field).to have_properties({
        foo: feature_values.dig(:register_blocks, 0, :registers, 1, :bit_fields, 0, :foo),
        bar: feature_values.dig(:register_blocks, 0, :registers, 1, :bit_fields, 0, :bar)
      })

      register_block = root.register_blocks[1]
      expect(register_block).to have_properties({
        foo: feature_values.dig(:register_blocks, 1, :foo),
        bar: feature_values.dig(:register_blocks, 1, :bar)
      })

      register_file = register_block.files_and_registers[0]
      expect(register_file).to have_properties({
        foo: feature_values.dig(:register_blocks, 1, :register_files, 0, :foo),
        bar: feature_values.dig(:register_blocks, 1, :register_files, 0, :bar)
      })

      register = register_file.files_and_registers[0]
      expect(register).to have_properties({
        foo: feature_values.dig(:register_blocks, 1, :register_files, 0, :registers, 0, :foo),
        bar: feature_values.dig(:register_blocks, 1, :register_files, 0, :registers, 0, :bar)
      })

      bit_field = register.bit_fields[0]
      expect(bit_field).to have_properties({
        foo: feature_values.dig(:register_blocks, 1, :register_files, 0, :registers, 0, :bit_fields, 0, :foo),
        bar: feature_values.dig(:register_blocks, 1, :register_files, 0, :registers, 0, :bit_fields, 0, :bar)
      })

      register_file = register_block.files_and_registers[1]
      expect(register_file).to have_properties({
        foo: feature_values.dig(:register_blocks, 1, :register_files, 1, :foo),
        bar: feature_values.dig(:register_blocks, 1, :register_files, 1, :bar)
      })

      register = register_file.files_and_registers[0]
      expect(register).to have_properties({
        foo: feature_values.dig(:register_blocks, 1, :register_files, 1, :registers, 0, :foo),
        bar: feature_values.dig(:register_blocks, 1, :register_files, 1, :registers, 0, :bar)
      })

      bit_field = register.bit_fields[0]
      expect(bit_field).to have_properties({
        foo: feature_values.dig(:register_blocks, 1, :register_files, 1, :registers, 0, :bit_fields, 0, :foo),
        bar: feature_values.dig(:register_blocks, 1, :register_files, 1, :registers, 0, :bit_fields, 0, :bar)
      })

      register = register_block.files_and_registers[2]
      expect(register).to have_properties({
        foo: feature_values.dig(:register_blocks, 1, :registers, 0, :foo),
        bar: feature_values.dig(:register_blocks, 1, :registers, 0, :bar)
      })

      bit_field = register.bit_fields[0]
      expect(bit_field).to have_properties({
        foo: feature_values.dig(:register_blocks, 1, :registers, 0, :bit_fields, 0, :foo),
        bar: feature_values.dig(:register_blocks, 1, :registers, 0, :bit_fields, 0, :bar)
      })

      bit_field = register.bit_fields[1]
      expect(bit_field).to have_properties({
        foo: feature_values.dig(:register_blocks, 1, :registers, 0, :bit_fields, 1, :foo),
        bar: feature_values.dig(:register_blocks, 1, :registers, 0, :bit_fields, 1, :bar)
      })
    end
  end
end
