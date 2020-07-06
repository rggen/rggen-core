# frozen_string_literal: true

RSpec.describe RgGen::Core::Base::FeatureLayerExtension do
  before(:all) do
    @component_class = Class.new(RgGen::Core::Base::Component) do
      include RgGen::Core::Base::ComponentLayerExtension
      def post_initialize(*_)
        parent&.add_child(self)
        define_layer_methods
      end
    end

    @feature_class = Class.new(RgGen::Core::Base::Feature) do
      include RgGen::Core::Base::FeatureLayerExtension
      def post_initialize
        define_layer_methods
      end
    end
  end

  let(:root) do
    @component_class.new(nil, :component, :root)
  end

  let(:register_block) do
    root
    @component_class.new(root, :component, :register_block)
  end

  let(:register_files) do
    register_block
    [
      @component_class.new(register_block, :component, :register_file),
      @component_class.new(register_block.children[0], :component, :register_file),
      @component_class.new(register_block.children[0].children[0], :component, :register_file)
    ]
  end

  let(:registers) do
    register_files
    [
      @component_class.new(register_block, :component, :register),
      @component_class.new(register_files[0], :component, :register),
      @component_class.new(register_files[1], :component, :register)
    ]
  end

  let(:bit_fields) do
    registers
    registers.map do |register|
      @component_class.new(register, :component, :bit_field)
    end
  end

  context 'componentの階層がnilの場合' do
    it 'エラーなくnewできる' do
      component = @component_class.new(nil, :component, nil)
      expect { @feature_class.new('', '', component) }.not_to raise_error
    end
  end

  context 'componentがroot階層の場合' do
    let(:feature) do
      @feature_class.new('', '', root)
    end

    describe '#root' do
      it '属するルートオブジェクトを返す' do
        expect(feature.root).to equal root
      end
    end

    describe '#root?' do
      it '真を返す' do
        expect(feature).to be_root
      end
    end

    describe '#register_block?' do
      it '偽を返す' do
        expect(feature).not_to be_register_block
      end
    end

    describe '#register_file?' do
      it '偽を返す' do
        expect(feature).not_to be_register_file
      end
    end

    describe '#register?' do
      it '偽を返す' do
        expect(feature).not_to be_register
      end
    end

    describe '#bit_field?' do
      it '偽を返す' do
        expect(feature).not_to be_bit_field
      end
    end
  end

  context 'componentがregister_block階層の場合' do
    let(:feature) do
      @feature_class.new('', '', register_block)
    end

    describe '#root' do
      it '属するルートオブジェクトを返す' do
        expect(feature.root).to equal root
      end
    end

    describe '#register_block' do
      it '属するレジスタブロックオブジェクトを返す' do
        expect(feature.register_block).to equal register_block
      end
    end

    describe '#register_blocks' do
      before { feature }

      it '同一階層上のレジスタブロックオブジェクトの一覧を返す' do
        sibships =
          Array.new(2) { @component_class.new(root, :component, :register_block) }
        expect(feature.register_blocks).to match [
          equal(register_block), equal(sibships[0]), equal(sibships[1])
        ]
      end
    end

    describe '#root?' do
      it '偽を返す' do
        expect(feature).not_to be_root
      end
    end

    describe '#register_block?' do
      it '真を返す' do
        expect(feature).to be_register_block
      end
    end

    describe '#register_file?' do
      it '偽を返す' do
        expect(feature).not_to be_register_file
      end
    end

    describe '#register?' do
      it '偽を返す' do
        expect(feature).not_to be_register
      end
    end

    describe '#bit_field?' do
      it '偽を返す' do
        expect(feature).not_to be_bit_field
      end
    end
  end

  context 'componentがregister_file階層の場合' do
    let(:features) do
      register_files.map do |register_file|
        @feature_class.new('', '', register_file)
      end
    end

    describe '#root' do
      it '属するルートオブジェクトを返す' do
        expect(features[0].root).to equal root
        expect(features[1].root).to equal root
        expect(features[2].root).to equal root
      end
    end

    describe '#register_block' do
      it '属するレジスタブロックオブジェクトを返す' do
        expect(features[0].register_block).to equal register_block
        expect(features[1].register_block).to equal register_block
        expect(features[2].register_block).to equal register_block
      end
    end

    describe '#block_or_file' do
      it '属するのレジスタブロックオブジェクト、または、レジスタファイルオブジェクトを返す' do
        expect(features[0].block_or_file).to equal register_block
        expect(features[1].block_or_file).to equal register_files[0]
        expect(features[2].block_or_file).to equal register_files[1]
      end
    end

    describe '#register_file' do
      context '無引数の場合' do
        it '属するレジスタファイルオブジェクトを返す' do
          expect(features[0].register_file).to equal register_files[0]
          expect(features[1].register_file).to equal register_files[1]
          expect(features[2].register_file).to equal register_files[2]
        end
      end

      context '引数に:upperが指定された場合' do
        it '属する上位のレジスタファイルオブジェクトを返す' do
          expect(features[0].register_file(:upper)).to be_nil
          expect(features[1].register_file(:upper)).to equal register_files[0]
          expect(features[2].register_file(:upper)).to equal register_files[1]
        end
      end
    end

    describe '#files_and_registers' do
      before { features }

      it '同一階層上のレジスタファイルオブジェクトとレジスタオブジェクトの一覧を返す' do
        sibships = [
          @component_class.new(register_block, :component, :register_file),
          @component_class.new(register_block, :component, :register)
        ]
        expect(features[0].files_and_registers).to match [
          equal(register_files[0]), equal(sibships[0]), equal(sibships[1])
        ]

        sibships = [
          @component_class.new(register_files[0], :component, :register_file),
          @component_class.new(register_files[0], :component, :register)
        ]
        expect(features[1].files_and_registers).to match [
          equal(register_files[1]), equal(sibships[0]), equal(sibships[1])
        ]

        sibships = [
          @component_class.new(register_files[1], :component, :register_file),
          @component_class.new(register_files[1], :component, :register)
        ]
        expect(features[2].files_and_registers).to match [
          equal(register_files[2]), equal(sibships[0]), equal(sibships[1])
        ]
      end
    end

    describe '#root?' do
      it '偽を返す' do
        expect(features[0]).not_to be_root
      end
    end

    describe '#register_block?' do
      it '偽を返す' do
        expect(features[0]).not_to be_register_block
      end
    end

    describe '#register_file?' do
      it '真を返す' do
        expect(features[0]).to be_register_file
      end
    end

    describe '#register?' do
      it '偽を返す' do
        expect(features[0]).not_to be_register
      end
    end

    describe '#bit_field?' do
      it '偽を返す' do
        expect(features[0]).not_to be_bit_field
      end
    end
  end

  describe 'componentがregister階層の場合' do
    let(:features) do
      registers.map do |register|
        @feature_class.new('', '', register)
      end
    end

    describe '#root' do
      it '属するルートオブジェクトを返す' do
        expect(features[0].root).to equal root
        expect(features[1].root).to equal root
        expect(features[2].root).to equal root
      end
    end

    describe '#register_block' do
      it '属するレジスタブロックオブジェクトを返す' do
        expect(features[0].register_block).to equal register_block
        expect(features[1].register_block).to equal register_block
        expect(features[2].register_block).to equal register_block
      end
    end

    describe '#register_file' do
      it '属するレジスタファイルオブジェクトを返す' do
        expect(features[0].register_file).to be_nil
        expect(features[1].register_file).to equal register_files[0]
        expect(features[2].register_file).to equal register_files[1]
      end
    end

    describe '#register_files' do
      it '階層上のレジスタファイルオブジェクトの一覧を返す' do
        expect(features[0].register_files).to be_empty
        expect(features[1].register_files).to match([equal(register_files[0])])
        expect(features[2].register_files).to match([equal(register_files[0]), equal(register_files[1])])
      end
    end

    describe '#block_or_file' do
      it '属するレジスタブロックオブジェクト、または、レジスタファイルオブジェクトを返す' do
        expect(features[0].block_or_file).to equal register_block
        expect(features[1].block_or_file).to equal register_files[0]
        expect(features[2].block_or_file).to equal register_files[1]
      end
    end

    describe '#register' do
      it '属するレジスタオブジェクトを返す' do
        expect(features[0].register).to equal registers[0]
        expect(features[1].register).to equal registers[1]
        expect(features[2].register).to equal registers[2]
      end
    end

    describe '#files_and_registers' do
      before { features }

      it '同一階層上のレジスタファイルオブジェクトとレジスタオブジェクトの一覧を返す' do
        sibships = [
          @component_class.new(register_block, :component, :register_file),
          @component_class.new(register_block, :component, :register)
        ]
        expect(features[0].files_and_registers).to match [
          equal(register_files[0]), equal(registers[0]), equal(sibships[0]), equal(sibships[1])
        ]

        sibships = [
          @component_class.new(register_files[0], :component, :register_file),
          @component_class.new(register_files[0], :component, :register)
        ]
        expect(features[1].files_and_registers).to match [
          equal(register_files[1]), equal(registers[1]), equal(sibships[0]), equal(sibships[1])
        ]

        sibships = [
          @component_class.new(register_files[1], :component, :register_file),
          @component_class.new(register_files[1], :component, :register)
        ]
        expect(features[2].files_and_registers).to match [
          equal(register_files[2]), equal(registers[2]), equal(sibships[0]), equal(sibships[1])
        ]
      end
    end

    describe '#root?' do
      it '偽を返す' do
        expect(features[0]).not_to be_root
      end
    end

    describe '#register_block?' do
      it '偽を返す' do
        expect(features[0]).not_to be_register_block
      end
    end

    describe '#register_file?' do
      it '偽を返す' do
        expect(features[0]).not_to be_register_file
      end
    end

    describe '#register?' do
      it '真を返す' do
        expect(features[0]).to be_register
      end
    end

    describe '#bit_field?' do
      it '偽を返す' do
        expect(features[0]).not_to be_bit_field
      end
    end
  end

  context 'componentがbit_field階層の場合' do
    let(:features) do
      bit_fields.map do |bit_field|
        @feature_class.new('', '', bit_field)
      end
    end

    describe '#root' do
      it '属するルートオブジェクトを返す' do
        expect(features[0].root).to equal root
        expect(features[1].root).to equal root
        expect(features[2].root).to equal root
      end
    end

    describe '#register_block' do
      it '属するレジスタブロックオブジェクトを返す' do
        expect(features[0].register_block).to equal register_block
        expect(features[1].register_block).to equal register_block
        expect(features[2].register_block).to equal register_block
      end
    end

    describe '#register_file' do
      it '属するレジスタファイルオブジェクトを返す' do
        expect(features[0].register_file).to be_nil
        expect(features[1].register_file).to equal register_files[0]
        expect(features[2].register_file).to equal register_files[1]
      end
    end

    describe '#register_files' do
      it '階層上のレジスタファイルオブジェクトの一覧を返す' do
        expect(features[0].register_files).to be_empty
        expect(features[1].register_files).to match([equal(register_files[0])])
        expect(features[2].register_files).to match([equal(register_files[0]), equal(register_files[1])])
      end
    end

    describe '#register' do
      it '属するレジスタオブジェクトを返す' do
        expect(features[0].register).to equal registers[0]
        expect(features[1].register).to equal registers[1]
        expect(features[2].register).to equal registers[2]
      end
    end

    describe '#bit_field' do
      it '属するビットフィールドオブジェクトを返す' do
        expect(features[0].bit_field).to equal bit_fields[0]
        expect(features[1].bit_field).to equal bit_fields[1]
        expect(features[2].bit_field).to equal bit_fields[2]
      end
    end

    describe '#bit_fields' do
      before { features }

      it '同一階層上のビットフィールドオブジェクトの一覧を返す' do
        sibships =
          Array.new(2) { @component_class.new(registers[0], :component, :bit_field) }
        expect(features[0].bit_fields).to match [
          equal(bit_fields[0]), equal(sibships[0]), equal(sibships[1])
        ]
      end
    end

    describe '#root?' do
      it '偽を返す' do
        expect(features[0]).not_to be_root
      end
    end

    describe '#register_block?' do
      it '偽を返す' do
        expect(features[0]).not_to be_register_block
      end
    end

    describe '#register_file?' do
      it '偽を返す' do
        expect(features[0]).not_to be_register_file
      end
    end

    describe '#register?' do
      it '偽を返す' do
        expect(features[0]).not_to be_register
      end
    end

    describe '#bit_field?' do
      it '真を返す' do
        expect(features[0]).to be_bit_field
      end
    end
  end
end
