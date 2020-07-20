# frozen_string_literal: true

RSpec.describe RgGen::Core::RegisterMap::ComponentFactory do
  def define_feature(feature_name, &body)
    feature_body = body || proc { |v| instance_variable_set("@#{feature_name}", v) }
    Class.new(RgGen::Core::RegisterMap::Feature) do
      property feature_name
      build(&feature_body)
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

  let(:register_baz_feature) { define_feature(:baz) { |v| v && component.need_no_children } }
  let(:register_baz_feature_factory) { create_feature_factory(:baz, register_baz_feature) }

  let(:register_feature_factories) do
    {
      foo: register_foo_feature_factory,
      bar: register_bar_feature_factory,
      baz: register_baz_feature_factory
    }
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

  let(:file_baz_feature) { define_feature(:baz) { |v| v && component.need_no_children } }
  let(:file_baz_feature_factory) { create_feature_factory(:baz, file_baz_feature) }

  let(:file_feature_factories) do
    {
      foo: file_foo_feature_factory,
      bar: file_bar_feature_factory,
      baz: file_baz_feature_factory
    }
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

  let(:block_baz_feature) { define_feature(:baz) { |v| v && component.need_no_children } }
  let(:block_baz_feature_factory) { create_feature_factory(:baz, block_baz_feature) }

  let(:block_feature_factories) do
    {
      foo: block_foo_feature_factory,
      bar: block_bar_feature_factory,
      baz: block_baz_feature_factory
    }
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
        f.loaders [RgGen::Core::RegisterMap::JSONLoader.new([], {})]
      end
  end

  def setup_read_data(data)
    json = JSON.dump(data)
    allow(File).to receive(:binread).with(file).and_return(json)
  end

  def raise_register_map_error(message = nil, position = nil)
    raise_rggen_error(RgGen::Core::RegisterMap::RegisterMapError, message, position)
  end

  describe '#create' do
    let(:file) { 'foo.json' }

    let(:configuration) { RgGen::Core::Configuration::Component.new(nil, 'configuration', nil) }

    before do
      allow(File).to receive(:readable?).with(file).and_return(true)
    end

    describe '#コンポーネントの生成' do
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

      it 'レジスタマップコンポーネントの生成と組み立てを行う' do
        setup_read_data(feature_values)
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

    describe '#子コンポーネントの有無の確認' do
      context '子コンポーネントの指定がない場合' do
        it 'RegisterMapErrorを起こす' do
          setup_read_data({})
          expect {
            root_component_factory.create(configuration, [file])
          }.to raise_register_map_error 'no register blocks are given'

          setup_read_data({
            register_blocks: [{}]
          })
          expect {
            root_component_factory.create(configuration, [file])
          }.to raise_register_map_error 'neither register files nor registers are given'

          setup_read_data({
            register_blocks: [
              register_files: [{}]
            ]
          })
          expect {
            root_component_factory.create(configuration, [file])
          }.to raise_register_map_error 'neither register files nor registers are given'

          setup_read_data({
            register_blocks: [
              registers: [{}]
            ]
          })
          expect {
            root_component_factory.create(configuration, [file])
          }.to raise_register_map_error 'no bit fields are given'
        end
      end

      context '#need_no_childrenが指定された場合' do
        it 'RegisterMapErrorは起こさない' do
          setup_read_data({
            register_blocks: [ { baz: true }]
          })
          expect {
            root_component_factory.create(configuration, [file])
          }.not_to raise_error

          setup_read_data({
            register_blocks: [
              register_files: [ { baz: true }]
            ]
          })
          expect {
            root_component_factory.create(configuration, [file])
          }.not_to raise_error

          setup_read_data({
            register_blocks: [
              registers: [ { baz: true }]
            ]
          })
          expect {
            root_component_factory.create(configuration, [file])
          }.not_to raise_error
        end
      end

      context 'ComponentFacotry.disable_no_children_errorが指定された場合' do
        after { described_class.enable_no_children_error }

        it 'RegisterMapErrorは起こさない' do
          described_class.disable_no_children_error

          setup_read_data({})
          expect {
            root_component_factory.create(configuration, [file])
          }.not_to raise_error

          setup_read_data({
            register_blocks: [{}]
          })
          expect {
            root_component_factory.create(configuration, [file])
          }.not_to raise_error

          setup_read_data({
            register_blocks: [
              register_files: [{}]
            ]
          })
          expect {
            root_component_factory.create(configuration, [file])
          }.not_to raise_error

          setup_read_data({
            register_blocks: [
              registers: [{}]
            ]
          })
          expect {
            root_component_factory.create(configuration, [file])
          }.not_to raise_error
        end
      end
    end
  end
end
