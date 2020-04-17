# frozen_string_literal: true

RSpec.describe RgGen::Core::Base::ComponentLayerExtension do
  before(:all) do
    @klass = Class.new(RgGen::Core::Base::Component) do
      include RgGen::Core::Base::ComponentLayerExtension
      def post_initialize(*_)
        parent&.add_child(self)
        define_layer_methods
      end
    end
  end

  let!(:root) do
    @klass.new(nil, :component, :root)
  end

  let!(:register_blocks) do
    Array.new(3) { @klass.new(root, :component, :register_block) }
  end

  let!(:register_files) do
    [
      @klass.new(register_blocks[0], :component, :register_file),
      @klass.new(register_blocks[0], :component, :register_file),
      @klass.new(register_blocks[1], :component, :register_file),
      @klass.new(register_blocks[0].children[1], :component, :register_file),
      @klass.new(register_blocks[0].children[1], :component, :register_file),
      @klass.new(register_blocks[0].children[1].children[0], :component, :register_file)
    ]
  end

  let!(:registers) do
    [
      @klass.new(register_files[0], :component, :register),
      @klass.new(register_files[0], :component, :register),
      @klass.new(register_blocks[1], :component, :register),
      @klass.new(register_blocks[2], :component, :register),
      @klass.new(register_blocks[2], :component, :register),
      @klass.new(register_files[3], :component, :register),
      @klass.new(register_files[5], :component, :register)
    ]
  end

  let!(:bit_fields) do
    [
      @klass.new(registers[0], :component, :bit_field),
      @klass.new(registers[0], :component, :bit_field),
      @klass.new(registers[3], :component, :bit_field),
      @klass.new(registers[5], :component, :bit_field),
      @klass.new(registers[6], :component, :bit_field)
    ]
  end

  context 'root階層の場合' do
    describe '#register_blocks' do
      it '配下のレジスタブロックオブジェクトを返す' do
        expect(root.register_blocks).to match [
          equal(register_blocks[0]), equal(register_blocks[1]), equal(register_blocks[2])
        ]
      end
    end

    describe '#register_files' do
      it '配下のレジスタファイルオブジェクトを返す' do
        expect(root.register_files).to match [
          equal(register_files[0]), equal(register_files[1]), equal(register_files[3]),
          equal(register_files[5]), equal(register_files[4]), equal(register_files[2])
        ]
      end
    end

    describe '#registers' do
      it '配下のレジスタオブジェクトを返す' do
        expect(root.registers).to match [
          equal(registers[0]), equal(registers[1]), equal(registers[6]),
          equal(registers[5]), equal(registers[2]), equal(registers[3]),
          equal(registers[4])
        ]
      end
    end

    describe '#bit_fields' do
      it '配下のビットフィールドを返す' do
        expect(root.bit_fields).to match [
          equal(bit_fields[0]), equal(bit_fields[1]), equal(bit_fields[4]),
          equal(bit_fields[3]), equal(bit_fields[2])
        ]
      end
    end

    describe '#root?' do
      it '真を返す' do
        expect(root).to be_root
      end
    end

    describe '#register_block?' do
      it '偽を返す' do
        expect(root).not_to be_register_block
      end
    end

    describe '#register_file?' do
      it '偽を返す' do
        expect(root).not_to be_register_file
      end
    end

    describe '#register?' do
      it '偽を返す' do
        expect(root).not_to be_register
      end
    end

    describe '#bit_field?' do
      it '偽を返す' do
        expect(root).not_to be_bit_field
      end
    end
  end

  context 'register_block階層の場合' do
    describe '#root' do
      it '属するルートオブジェクトを返す' do
        expect(register_blocks[0].root).to equal root
      end
    end

    describe '#files_and_registers' do
      it '直下のレジスタファイルオブジェクトとレジスタオブジェクトの一覧を返す' do
        expect(register_blocks[0].files_and_registers).to match [
          equal(register_files[0]), equal(register_files[1])
        ]

        expect(register_blocks[1].files_and_registers).to match [
          equal(register_files[2]), equal(registers[2])
        ]

        expect(register_blocks[2].files_and_registers).to match [
          equal(registers[3]), equal(registers[4])
        ]
      end
    end

    describe '#register_files' do
      context '無引数の場合' do
        it '配下のレジスタファイルオブジェクトを返す' do
          expect(register_blocks[0].register_files).to match [
            equal(register_files[0]), equal(register_files[1]), equal(register_files[3]),
            equal(register_files[5]), equal(register_files[4])
          ]

          expect(register_blocks[1].register_files).to match [
            equal(register_files[2])
          ]

          expect(register_blocks[2].register_files).to be_empty
        end
      end

      context '引数にfalseが指定された場合' do
        it '直下のレジスタファイルオブジェクトを返す' do
          expect(register_blocks[0].register_files(false)).to match [
            equal(register_files[0]), equal(register_files[1])
          ]

          expect(register_blocks[1].register_files(false)).to match [
            equal(register_files[2])
          ]

          expect(register_blocks[2].register_files(false)).to be_empty
        end
      end
    end

    describe '#registers' do
      context '無引数の場合' do
        it '配下のレジスタオブジェクトを返す' do
          expect(register_blocks[0].registers).to match [
            equal(registers[0]), equal(registers[1]),
            equal(registers[6]), equal(registers[5])
          ]

          expect(register_blocks[1].registers).to match [
            equal(registers[2])
          ]

          expect(register_blocks[2].registers).to match [
            equal(registers[3]), equal(registers[4])
          ]
        end
      end

      context '引数にfalseが指定された場合' do
        it '直下のレジスタオブジェクトを返す' do
          expect(register_blocks[0].registers(false)).to be_empty

          expect(register_blocks[1].registers(false)).to match [
            equal(registers[2])
          ]

          expect(register_blocks[2].registers(false)).to match [
            equal(registers[3]), equal(registers[4])
          ]
        end
      end
    end

    describe '#bit_fields' do
      it '配下のビットフィールドオブジェクトを返す' do
        expect(register_blocks[0].bit_fields).to match [
          equal(bit_fields[0]), equal(bit_fields[1]),
          equal(bit_fields[4]), equal(bit_fields[3])
        ]

        expect(register_blocks[1].bit_fields).to be_empty

        expect(register_blocks[2].bit_fields).to match [
          equal(bit_fields[2])
        ]
      end
    end

    describe '#root?' do
      it '偽を返す' do
        expect(register_blocks[0]).not_to be_root
      end
    end

    describe '#register_block?' do
      it '真を返す' do
        expect(register_blocks[0]).to be_register_block
      end
    end

    describe '#register_file?' do
      it '偽を返す' do
        expect(register_blocks[0]).not_to be_register_file
      end
    end

    describe '#register?' do
      it '偽を返す' do
        expect(register_blocks[0]).not_to be_register
      end
    end

    describe '#bit_field?' do
      it '偽を返す' do
        expect(register_blocks[0]).not_to be_bit_field
      end
    end
  end

  context 'register_file階層の場合' do
    describe '#root' do
      it '属するルートオブジェクトを返す' do
        expect(register_files[0].root).to equal root
        expect(register_files[2].root).to equal root
        expect(register_files[3].root).to equal root
        expect(register_files[5].root).to equal root
      end
    end

    describe '#block_or_file' do
      it '属する直近のレジスタブロックオブジェクト、または、レジスタファイルオブジェクトを返す' do
        expect(register_files[0].block_or_file).to equal register_blocks[0]
        expect(register_files[2].block_or_file).to equal register_blocks[1]
        expect(register_files[3].block_or_file).to equal register_files[1]
        expect(register_files[5].block_or_file).to equal register_files[3]
      end
    end

    describe '#register_block' do
      it '属する直近のレジスタブロックオブジェクトを返す' do
        expect(register_files[0].register_block).to equal register_blocks[0]
        expect(register_files[2].register_block).to equal register_blocks[1]
        expect(register_files[3].register_block).to equal register_blocks[0]
        expect(register_files[5].register_block).to equal register_blocks[0]
      end
    end

    describe '#files_and_registers' do
      it '直下のレジスタファイルオブジェクトとレジスタオブジェクトの一覧を返す' do
        expect(register_files[0].files_and_registers).to match [
          equal(registers[0]), equal(registers[1])
        ]

        expect(register_files[1].files_and_registers).to match [
          equal(register_files[3]), equal(register_files[4])
        ]

        expect(register_files[3].files_and_registers).to match [
          equal(register_files[5]), equal(registers[5])
        ]
      end
    end

    describe '#register_files' do
      context '無引数の場合' do
        it '配下のレジスタファイルオブジェクトを返す' do
          expect(register_files[0].register_files).to be_empty
          expect(register_files[1].register_files).to match [
            equal(register_files[3]), equal(register_files[5]), equal(register_files[4])
          ]
        end
      end

      context '引数にfalseが指定された場合' do
        it '直下のレジスタファイルオブジェクトを返す' do
          expect(register_files[0].register_files(false)).to be_empty

          expect(register_files[1].register_files(false)).to match [
            equal(register_files[3]), equal(register_files[4])
          ]
        end
      end
    end

    describe '#registers' do
      context '無引数の場合' do
        it '配下のレジスタオブジェクトを返す' do
          expect(register_files[0].registers).to match [
            equal(registers[0]), equal(registers[1])
          ]

          expect(register_files[1].registers).to match [
            equal(registers[6]), equal(registers[5])
          ]
        end
      end

      context '引数にfalseが指定された場合' do
        it '直下のレジスタオブジェクトを返す' do
          expect(register_files[0].registers(false)).to match [
            equal(registers[0]), equal(registers[1])
          ]

          expect(register_files[1].registers(false)).to be_empty
        end
      end
    end

    describe '#bit_fields' do
      it '配下のビットフィールドオブジェクトを返す' do
        expect(register_files[0].bit_fields).to match [
          equal(bit_fields[0]), equal(bit_fields[1])
        ]

        expect(register_files[1].bit_fields).to match [
          equal(bit_fields[4]), equal(bit_fields[3])
        ]
      end
    end

    describe '#root?' do
      it '偽を返す' do
        expect(register_files[0]).not_to be_root
      end
    end

    describe '#register_block?' do
      it '偽を返す' do
        expect(register_files[0]).not_to be_register_block
      end
    end

    describe '#register_file?' do
      it '真を返す' do
        expect(register_files[0]).to be_register_file
      end
    end

    describe '#register?' do
      it '偽を返す' do
        expect(register_files[0]).not_to be_register
      end
    end

    describe '#bit_field?' do
      it '偽を返す' do
        expect(register_files[0]).not_to be_bit_field
      end
    end
  end

  context 'register階層の場合' do
    describe '#root' do
      it '属するルートオブジェクトを返す' do
        expect(registers[0].root).to equal root
        expect(registers[2].root).to equal root
        expect(registers[3].root).to equal root
        expect(registers[5].root).to equal root
        expect(registers[6].root).to equal root
      end
    end

    describe '#register_block' do
      it '属するレジスタブロックオブジェクトを返す' do
        expect(registers[0].register_block).to equal register_blocks[0]
        expect(registers[2].register_block).to equal register_blocks[1]
        expect(registers[3].register_block).to equal register_blocks[2]
        expect(registers[5].register_block).to equal register_blocks[0]
        expect(registers[6].register_block).to equal register_blocks[0]
      end
    end

    describe '#register_file' do
      it '属するレジスタファイルオブジェクトを返す' do
        expect(registers[0].register_file).to equal register_files[0]
        expect(registers[2].register_file).to be_nil
        expect(registers[3].register_file).to be_nil
        expect(registers[5].register_file).to equal register_files[3]
        expect(registers[6].register_file).to equal register_files[5]
      end
    end

    describe '#block_or_file' do
      it '属するレジスタブロックオブジェクト、または、レジスタファイルオブジェクトを返す' do
        expect(registers[0].block_or_file).to equal register_files[0]
        expect(registers[2].block_or_file).to equal register_blocks[1]
        expect(registers[3].block_or_file).to equal register_blocks[2]
        expect(registers[5].block_or_file).to equal register_files[3]
        expect(registers[6].block_or_file).to equal register_files[5]
      end
    end

    describe '#bit_fields' do
      it '配下のビットフィールドオブジェクト一覧を返す' do
        expect(registers[0].bit_fields).to match [
          equal(bit_fields[0]), equal(bit_fields[1])
        ]
      end
    end

    describe '#root?' do
      it '偽を返す' do
        expect(registers[0]).not_to be_root
      end
    end

    describe '#register_block?' do
      it '偽を返す' do
        expect(registers[0]).not_to be_register_block
      end
    end

    describe '#register_file?' do
      it '偽を返す' do
        expect(registers[0]).not_to be_register_file
      end
    end

    describe '#register?' do
      it '真を返す' do
        expect(registers[0]).to be_register
      end
    end

    describe '#bit_field?' do
      it '偽を返す' do
        expect(registers[0]).not_to be_bit_field
      end
    end
  end

  context 'bit_field階層の場合' do
    describe '#root' do
      it '属するルートオブジェクトを返す' do
        expect(bit_fields[0].root).to equal root
        expect(bit_fields[2].root).to equal root
        expect(bit_fields[3].root).to equal root
        expect(bit_fields[4].root).to equal root
      end
    end

    describe '#register_block' do
      it '属するレジスタブロックオブジェクトを返す' do
        expect(bit_fields[0].register_block).to equal register_blocks[0]
        expect(bit_fields[2].register_block).to equal register_blocks[2]
        expect(bit_fields[3].register_block).to equal register_blocks[0]
        expect(bit_fields[4].register_block).to equal register_blocks[0]
      end
    end

    describe '#register_file' do
      it '属するレジスタファイルオブジェクトを返す' do
        expect(bit_fields[0].register_file).to equal register_files[0]
        expect(bit_fields[2].register_file).to be_nil
        expect(bit_fields[3].register_file).to equal register_files[3]
        expect(bit_fields[4].register_file).to equal register_files[5]
      end
    end

    describe '#register' do
      it '属するレジスタオブジェクトを返す' do
        expect(bit_fields[0].register).to equal registers[0]
        expect(bit_fields[2].register).to equal registers[3]
        expect(bit_fields[3].register).to equal registers[5]
        expect(bit_fields[4].register).to equal registers[6]
      end
    end

    describe '#root?' do
      it '偽を返す' do
        expect(bit_fields[0]).not_to be_root
      end
    end

    describe '#register_block?' do
      it '偽を返す' do
        expect(bit_fields[0]).not_to be_register_block
      end
    end

    describe '#register_file?' do
      it '偽を返す' do
        expect(bit_fields[0]).not_to be_register_file
      end
    end

    describe '#register?' do
      it '偽を返す' do
        expect(bit_fields[0]).not_to be_register
      end
    end

    describe '#bit_field?' do
      it '真を返す' do
        expect(bit_fields[0]).to be_bit_field
      end
    end
  end
end
