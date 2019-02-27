# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::RegisterMap
  describe HashLoader do
    let(:loader) do
      Class.new(Loader) do
        class << self
          attr_accessor :load_data
        end

        include HashLoader

        def read_file(file)
          self.class.load_data
        end
      end
    end

    let(:valid_value_lists) do
      [[], [:foo], [:bar], [:baz]]
    end

    let(:input_data) do
      InputData.new(:register_map, valid_value_lists)
    end

    let(:file) { 'foo.txt' }

    before do
      allow(File).to receive(:readable?).and_return(true)
    end

    context "#read_fileがレジスタマップを表すHashを返す場合" do
      let(:load_data) do
        {
          register_blocks: [
            {
              foo: 'foo_0',
              registers: [
                {
                  bar: 'bar_0_0',
                  bit_fields: [
                    { baz: 'baz_0_0_0' },
                    { baz: 'baz_0_0_1' }
                  ]
                },
                {
                  bar: 'bar_0_1',
                  bit_fields: [
                    { baz: 'baz_0_1_0' }
                  ]
                }
              ]
            },
            {
              'foo' => 'foo_1',
              'registers' => [
                {
                  'bar' => 'bar_1_0',
                  'bit_fields' => [
                    { 'baz' => 'baz_1_0_0' }
                  ]
                },
                {
                  'bar' => 'bar_1_1',
                  bit_fields: [
                    { 'baz' => 'baz_1_1_0' },
                    { 'baz' => 'baz_1_1_1' }
                  ]
                }
              ]
            }
          ]
        }
      end

      let(:register_blocks) { input_data.children }

      let(:registers) { register_blocks.flat_map(&:children) }

      let(:bit_fields) { registers.flat_map(&:children) }

      before do
        loader.load_data = load_data
        loader.load_file(file, input_data, valid_value_lists)
      end

      it "読み出したHashを使って、入力データを組み立てる" do
        expect(register_blocks).to match [
          have_value(:foo, 'foo_0'), have_value(:foo, 'foo_1')
        ]
        expect(registers).to match [
          have_value(:bar, 'bar_0_0'), have_value(:bar, 'bar_0_1'),
          have_value(:bar, 'bar_1_0'), have_value(:bar, 'bar_1_1')
        ]
        expect(bit_fields).to match [
          have_value(:baz, 'baz_0_0_0'), have_value(:baz, 'baz_0_0_1'), have_value(:baz, 'baz_0_1_0'),
          have_value(:baz, 'baz_1_0_0'), have_value(:baz, 'baz_1_1_0'), have_value(:baz, 'baz_1_1_1')
        ]
      end
    end

    context "#read_fileがHash以外を返す場合" do
      let(:invalid_load_data) do
        [0, Object.new, 'foo']
      end

      it "LoadErrorを起こす" do
        invalid_load_data.each do |load_data|
          expect {
            loader.load_data = load_data
            loader.load_file(file, input_data, valid_value_lists)
          }.to raise_error RgGen::Core::LoadError, "can't convert #{load_data.class} into Hash -- #{file}"
        end
      end
    end

    context "register_blocksの要素がHash出ない場合" do
      let(:invalid_data) do
        [0, Object.new, 'foo']
      end

      it "LoadErrorを起こす" do
        invalid_data.each do |data|
          loader.load_data = {
            register_blocks: [data]
          }
          expect {
            loader.load_file(file, input_data, valid_value_lists)
          }.to raise_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash -- #{file}"
        end
      end
    end

    context "registersの要素がHash出ない場合" do
      let(:invalid_data) do
        [0, Object.new, 'foo']
      end

      it "LoadErrorを起こす" do
        invalid_data.each do |data|
          loader.load_data = {
            register_blocks: [
              { registers: [data] }
            ]
          }
          expect {
            loader.load_file(file, input_data, valid_value_lists)
          }.to raise_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash -- #{file}"
        end
      end
    end

    context "bit_fieldsの要素がHash出ない場合" do
      let(:invalid_data) do
        [0, Object.new, 'foo']
      end

      it "LoadErrorを起こす" do
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
          }.to raise_error RgGen::Core::LoadError, "can't convert #{data.class} into Hash -- #{file}"
        end
      end
    end
  end
end
