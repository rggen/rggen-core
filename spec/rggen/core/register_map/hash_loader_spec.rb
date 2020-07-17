# frozen_string_literal: true

RSpec.describe RgGen::Core::RegisterMap::HashLoader do
  let(:loader) do
    loader_class = Class.new(RgGen::Core::RegisterMap::Loader) do
      include RgGen::Core::RegisterMap::HashLoader
      attr_accessor :load_data
      def read_file(_file)
        load_data
      end
    end
    loader_class.new([])
  end

  let(:valid_value_lists) do
    {
      root: [],  register_block: [:foo_0, :foo_1],
      register_file: [:bar_0, :bar_1], register: [:baz_0, :baz_1],
      bit_field: [:qux_0, :qux_1]
    }
  end

  let(:input_data) do
    RgGen::Core::RegisterMap::InputData.new(:root, valid_value_lists)
  end

  let(:file) { 'foo.txt' }

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
      *(input_data.layer == layer ? input_data : nil),
      *input_data.children.flat_map { |child| collect_target_data(child, layer) }
    ]
  end

  before do
    allow(File).to receive(:readable?).and_return(true)
  end

  context '#read_fileがレジスタマップを表すHashを返す場合' do
    let(:load_data) do
      {
        register_blocks: [
          {
            foo_0: 'foo_0',
            foo_1: 'foo_1',
            registers: [
              {
                baz_0: 'baz_0',
                baz_1: 'baz_1',
                bit_fields: [
                  { qux_0: 'qux_0', qux_1: 'qux_1' },
                  { qux_0: 'qux_2', qux_1: 'qux_3' }
                ]
              },
              {
                baz_0: 'baz_2',
                baz_1: 'baz_3',
                bit_fields: [
                  { qux_0: 'qux_4', qux_1: 'qux_5' }
                ]
              }
            ]
          },
          {
            foo_0: 'foo_2',
            foo_1: 'foo_3',
            register_files: [
              {
                bar_0: 'bar_0',
                bar_1: 'bar_1',
                registers: [
                  {
                    baz_0: 'baz_4',
                    baz_1: 'baz_5',
                    bit_fields: [
                      { qux_0: 'qux_6', qux_1: 'qux_7' }
                    ]
                  }
                ]
              },
              {
                bar_0: 'bar_2',
                bar_1: 'bar_3',
                registers: [
                  {
                    baz_0: 'baz_6',
                    baz_1: 'baz_7',
                    bit_fields: [
                      { qux_0: 'qux_8', qux_1: 'qux_9' }
                    ]
                  }
                ]
              }
            ],
            registers: [
              {
                baz_0: 'baz_8',
                baz_1: 'baz_9',
                bit_fields: [
                  { qux_0: 'qux_a', qux_1: 'qux_b' }
                ]
              }
            ]
          }
        ]
      }
    end

    it '読み出したHashを使って、入力データを組み立てる' do
      loader.load_data = load_data
      loader.load_file(file, input_data, valid_value_lists)

      expect(register_blocks).to match [
        have_values([:foo_0, 'foo_0'], [:foo_1, 'foo_1']),
        have_values([:foo_0, 'foo_2'], [:foo_1, 'foo_3'])
      ]
      expect(register_files).to match [
        have_values([:bar_0, 'bar_0'], [:bar_1, 'bar_1']),
        have_values([:bar_0, 'bar_2'], [:bar_1, 'bar_3'])
      ]
      expect(registers).to match [
        have_values([:baz_0, 'baz_0'], [:baz_1, 'baz_1']), have_values([:baz_0, 'baz_2'], [:baz_1, 'baz_3']),
        have_values([:baz_0, 'baz_4'], [:baz_1, 'baz_5']), have_values([:baz_0, 'baz_6'], [:baz_1, 'baz_7']),
        have_values([:baz_0, 'baz_8'], [:baz_1, 'baz_9'])
      ]
      expect(bit_fields).to match [
        have_values([:qux_0, 'qux_0'], [:qux_1, 'qux_1']), have_values([:qux_0, 'qux_2'], [:qux_1, 'qux_3']),
        have_values([:qux_0, 'qux_4'], [:qux_1, 'qux_5']), have_values([:qux_0, 'qux_6'], [:qux_1, 'qux_7']),
        have_values([:qux_0, 'qux_8'], [:qux_1, 'qux_9']), have_values([:qux_0, 'qux_a'], [:qux_1, 'qux_b'])
      ]
    end
  end

  context '#read_fileがレジスタマップを表すArrayを返す場合' do
    let(:load_data) do
      [
        {
          register_block: [
            { foo_0: 'foo_0' }, { foo_1: 'foo_1' },
            {
              register: [
                { baz_0: 'baz_0' }, { baz_1: 'baz_1' },
                { bit_field: [{ qux_0: 'qux_0' }, { qux_1: 'qux_1' }] },
                { bit_field: [{ qux_0: 'qux_2' }, { qux_1: 'qux_3' }] }
              ]
            },
            {
              register: [
                { baz_0: 'baz_2' }, { baz_1: 'baz_3' },
                { bit_field: [{ qux_0: 'qux_4' }, { qux_1: 'qux_5' }] }
              ]
            }
          ]
        },
        {
          register_block: [
            { foo_0: 'foo_2', foo_1: 'foo_3' },
            {
              register_file: [
                { bar_0: 'bar_0', bar_1: 'bar_1' },
                {
                  register: [
                    { baz_0: 'baz_4', baz_1: 'baz_5' },
                    { bit_field: [{ qux_0: 'qux_6', qux_1: 'qux_7' }]}
                  ]
                }
              ]
            },
            {
              register_file: [
                { bar_0: 'bar_2', bar_1: 'bar_3' },
                {
                  register: [
                    { baz_0: 'baz_6', baz_1: 'baz_7' },
                    { bit_field: [{ qux_0: 'qux_8', qux_1: 'qux_9' }] }
                  ]
                }
              ]
            },
            {
              register: [
                { baz_0: 'baz_8', baz_1: 'baz_9' },
                { bit_field: [{ qux_0: 'qux_a', qux_1: 'qux_b' }] }
              ]
            }
          ]
        }
      ]
    end

    it '読みだしたArrayを使って、入力データを組み立てる' do
      loader.load_data = load_data
      loader.load_file(file, input_data, valid_value_lists)

      expect(register_blocks).to match [
        have_values([:foo_0, 'foo_0'], [:foo_1, 'foo_1']),
        have_values([:foo_0, 'foo_2'], [:foo_1, 'foo_3'])
      ]
      expect(register_files).to match [
        have_values([:bar_0, 'bar_0'], [:bar_1, 'bar_1']),
        have_values([:bar_0, 'bar_2'], [:bar_1, 'bar_3'])
      ]
      expect(registers).to match [
        have_values([:baz_0, 'baz_0'], [:baz_1, 'baz_1']), have_values([:baz_0, 'baz_2'], [:baz_1, 'baz_3']),
        have_values([:baz_0, 'baz_4'], [:baz_1, 'baz_5']), have_values([:baz_0, 'baz_6'], [:baz_1, 'baz_7']),
        have_values([:baz_0, 'baz_8'], [:baz_1, 'baz_9'])
      ]
      expect(bit_fields).to match [
        have_values([:qux_0, 'qux_0'], [:qux_1, 'qux_1']), have_values([:qux_0, 'qux_2'], [:qux_1, 'qux_3']),
        have_values([:qux_0, 'qux_4'], [:qux_1, 'qux_5']), have_values([:qux_0, 'qux_6'], [:qux_1, 'qux_7']),
        have_values([:qux_0, 'qux_8'], [:qux_1, 'qux_9']), have_values([:qux_0, 'qux_a'], [:qux_1, 'qux_b'])
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
        loader.load_data = { register_blocks: [data] }
        expect {
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash", file

        loader.load_data = [register_block: [data]]
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
        loader.load_data = { register_blocks: [register_files: [data]] }
        expect {
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash", file

        loader.load_data = { register_blocks: [register_files: [register_files: [data]]] }
        expect {
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash", file

        loader.load_data = [register_block: [register_file: [data]]]
        expect {
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash", file

        loader.load_data = [register_block: [register_file: [register_file: [data]]]]
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
        loader.load_data = { register_blocks: [registers: [data]] }
        expect {
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash", file

        loader.load_data = { register_blocks: [register_files: [registers: [data]]] }
        expect {
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash", file

        loader.load_data = [register_block: [register: [data]]]
        expect {
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash", file

        loader.load_data = [register_block: [register_file: [register: [data]]]]
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
        loader.load_data = { register_blocks: [registers: [bit_fields: [data]]] }
        expect {
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash", file

        loader.load_data = [register_block: [register: [bit_field: [data]]]]
        expect {
          loader.load_file(file, input_data, valid_value_lists)
        }.to raise_rggen_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash", file
      end
    end
  end
end
