# frozen_string_literal: true

RSpec.describe RgGen::Core::RegisterMap::HashLoader do
  let(:loader) do
    Class.new(RgGen::Core::RegisterMap::Loader) do
      class << self
        attr_accessor :load_data
      end

      include RgGen::Core::RegisterMap::HashLoader

      def read_file(_file)
        self.class.load_data
      end
    end
  end

  let(:valid_value_lists) do
    [[], [:foo], [:bar], [:baz]]
  end

  let(:valid_value_lists) do
    {
      root: [],  register_block: [:foo],
      register_file: [:bar], register: [:baz], bit_field: [:qux]
    }
  end

  let(:input_data) do
    RgGen::Core::RegisterMap::InputData.new(:root, valid_value_lists)
  end

  let(:file) { 'foo.txt' }

  before do
    allow(File).to receive(:readable?).and_return(true)
  end

  context '#read_fileがレジスタマップを表すHashを返す場合' do
    let(:load_data) do
      {
        register_blocks: [
          {
            foo: 'foo_0',
            registers: [
              {
                baz: 'baz_0_0',
                bit_fields: [
                  { qux: 'qux_0_0_0' },
                  { qux: 'qux_0_0_1' }
                ]
              },
              {
                baz: 'baz_0_1',
                bit_fields: [
                  { qux: 'qux_0_1_0' }
                ]
              }
            ]
          },
          {
            foo: 'foo_1',
            register_files: [
              {
                bar: 'bar_1_0',
                registers: [
                  {
                    baz: 'baz_1_0_0',
                    bit_fields: [
                      { qux: 'qux_1_0_0_0' }
                    ]
                  }
                ]
              },
              {
                bar: 'bar_1_1',
                registers: [
                  {
                    baz: 'baz_1_1_0',
                    bit_fields: [
                      { qux: 'qux_1_1_0_0' }
                    ]
                  }
                ]
              }
            ],
            registers: [
              {
                baz: 'baz_1_2',
                bit_fields: [
                  { qux: 'qux_1_2_0' }
                ]
              }
            ]
          }
        ]
      }
    end

    let(:register_blocks) { input_data.children }

    let(:register_files) do
      collect_target_data(input_data, :register_file)
    end

    let(:registers) do
      collect_target_data(input_data, :register)
    end

    let(:bit_fields) { registers.flat_map(&:children) }

    def collect_target_data(input_data, layer)
      [
        *input_data.children.select { |data| data.layer == layer },
        *input_data.children.flat_map { |data| collect_target_data(data, layer) }
      ]
    end

    before do
      loader.load_data = load_data
      loader.load_file(file, input_data, valid_value_lists)
    end

    it '読み出したHashを使って、入力データを組み立てる' do
      expect(register_blocks).to match [
        have_value(:foo, 'foo_0'), have_value(:foo, 'foo_1')
      ]
      expect(register_files).to match [
        have_value(:bar, 'bar_1_0'), have_value(:bar, 'bar_1_1')
      ]
      expect(registers).to match [
        have_value(:baz, 'baz_0_0'), have_value(:baz, 'baz_0_1'), have_value(:baz, 'baz_1_2'),
        have_value(:baz, 'baz_1_0_0'), have_value(:baz, 'baz_1_1_0'),
      ]
      expect(bit_fields).to match [
        have_value(:qux, 'qux_0_0_0'), have_value(:qux, 'qux_0_0_1'), have_value(:qux, 'qux_0_1_0'),
        have_value(:qux, 'qux_1_2_0'), have_value(:qux, 'qux_1_0_0_0'), have_value(:qux, 'qux_1_1_0_0')
      ]
    end
  end

  context '#read_fileがHash以外を返す場合' do
    let(:invalid_load_data) do
      [0, Object.new, 'foo']
    end

    it 'LoadErrorを起こす' do
      invalid_load_data.each do |load_data|
        expect {
          loader.load_data = load_data
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{load_data.class} into Hash", file
      end
    end
  end

  context 'register_blocksの要素がHashではない場合' do
    let(:invalid_data) do
      [0, Object.new, 'foo']
    end

    it 'LoadErrorを起こす' do
      invalid_data.each do |data|
        loader.load_data = {
          register_blocks: [data]
        }
        expect {
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash", file
      end
    end
  end

  context 'register_filesの要素がHashではない場合' do
    let(:invalid_data) do
      [0, Object.new, 'bar']
    end

    it 'LoadErrorを起こす' do
      invalid_data.each do |data|
        loader.load_data = {
          register_blocks: [
            register_files: [data]
          ]
        }
        expect {
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash", file

        loader.load_data = {
          register_blocks: [
            register_files: [
              register_files: [data]
            ]
          ]
        }
        expect {
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash", file
      end
    end
  end

  context 'registersの要素がHashではない場合' do
    let(:invalid_data) do
      [0, Object.new, 'foo']
    end

    it 'LoadErrorを起こす' do
      invalid_data.each do |data|
        loader.load_data = {
          register_blocks: [
            { registers: [data] }
          ]
        }
        expect {
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash", file

        loader.load_data = {
          register_blocks: [
            register_files: [
              registers: [data]
            ]
          ]
        }
        expect {
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash", file
      end
    end
  end

  context 'bit_fieldsの要素がHash出ない場合' do
    let(:invalid_data) do
      [0, Object.new, 'foo']
    end

    it 'LoadErrorを起こす' do
      invalid_data.each do |data|
        loader.load_data = {
          register_blocks: [{
            registers: [{
              bit_fields: [data]
            }]
          }]
        }
        expect {
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash", file
      end
    end
  end
end
