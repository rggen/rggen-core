# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RgGen::Core::RegisterMap::InputData do
  let(:valid_value_lists) do
    {
      root: [], register_block: [:foo],
      register_file: [:bar], register: [:baz], bit_field: [:qux]
    }
  end

  let(:position) do
    Struct.new(:x, :y).new(0, 1)
  end

  def create_input_data(layer, configuration = nil)
    described_class.new(layer, valid_value_lists, configuration)
  end

  def input_value(value)
    RgGen::Core::InputBase::InputValue.new(value, position)
  end

  def raise_register_map_error(message)
    raise_error RgGen::Core::RegisterMap::RegisterMapError, message
  end

  describe '#value/#[]=' do
    context '入力値名が入力値リスト上にない場合' do
      it 'RegisterMapErrorを起こす' do
        input_data = create_input_data(:register_block)
        expect { input_data.value(:bar, input_value(0)) }
          .to raise_register_map_error 'unknown register map field is given: bar'
        expect { input_data.value('bar', input_value(0)) }
          .to raise_register_map_error 'unknown register map field is given: bar'
        expect { input_data[:bar] = input_value(0) }
          .to raise_register_map_error 'unknown register map field is given: bar'
        expect { input_data['bar'] = input_value(0) }
          .to raise_register_map_error 'unknown register map field is given: bar'
        expect { input_data.value(:foo, input_value(0)) }
          .not_to raise_error
        expect { input_data[:foo] = input_value(0) }
          .not_to raise_error

        input_data = create_input_data(:register_file)
        expect { input_data.value(:foo, input_value(0)) }
          .to raise_register_map_error 'unknown register map field is given: foo'
        expect { input_data.value('foo', input_value(0)) }
          .to raise_register_map_error 'unknown register map field is given: foo'
        expect { input_data[:foo] = input_value(0) }
          .to raise_register_map_error 'unknown register map field is given: foo'
        expect { input_data['foo'] = input_value(0) }
          .to raise_register_map_error 'unknown register map field is given: foo'
        expect { input_data.value(:bar, input_value(0)) }
          .not_to raise_error
        expect { input_data[:bar] = input_value(0) }
          .not_to raise_error

        input_data = create_input_data(:register)
        expect { input_data.value(:qux, input_value(0)) }
          .to raise_register_map_error 'unknown register map field is given: qux'
        expect { input_data.value('qux', input_value(0)) }
          .to raise_register_map_error 'unknown register map field is given: qux'
        expect { input_data[:qux] = input_value(0) }
          .to raise_register_map_error 'unknown register map field is given: qux'
        expect { input_data['qux'] = input_value(0) }
          .to raise_register_map_error 'unknown register map field is given: qux'
        expect { input_data.value(:baz, input_value(0)) }
          .not_to raise_error
        expect { input_data[:baz] = input_value(0) }
          .not_to raise_error

        input_data = create_input_data(:bit_field)
        expect { input_data.value(:baz, input_value(0)) }
          .to raise_register_map_error 'unknown register map field is given: baz'
        expect { input_data.value('baz', input_value(0)) }
          .to raise_register_map_error 'unknown register map field is given: baz'
        expect { input_data[:baz] = input_value(0) }
          .to raise_register_map_error 'unknown register map field is given: baz'
        expect { input_data['baz'] = input_value(0) }
          .to raise_register_map_error 'unknown register map field is given: baz'
        expect { input_data.value(:qux, input_value(0)) }
          .not_to raise_error
        expect { input_data[:qux] = input_value(0) }
          .not_to raise_error
      end
    end
  end

  context '階層がrootの場合' do
    let(:input_data) do
      create_input_data(:root)
    end

    describe '#register_block' do
      it '子入力データを追加する' do
        expect {
          input_data.register_block {}
        }.to change { input_data.children.size }.from(0).to(1)
      end

      specify '追加される子入力データの階層はregister_blockである' do
        input_data.register_block {}
        expect(input_data.children[0].layer).to eq :register_block
      end
    end
  end

  context '階層がregister_blockの場合' do
    let(:input_data) do
      create_input_data(:register_block)
    end

    describe '#register_file' do
      it '子入力データを追加する' do
        expect {
          input_data.register_file {}
        }.to change { input_data.children.size }.from(0).to(1)
      end

      specify '追加される子入力データの階層はregister_fileである' do
        input_data.register_file {}
        expect(input_data.children[0].layer).to eq :register_file
      end
    end

    describe '#register' do
      it '子入力データを追加する' do
        expect {
          input_data.register {}
        }.to change { input_data.children.size }.from(0).to(1)
      end

      specify '追加される子入力データの階層はregisterである' do
        input_data.register {}
        expect(input_data.children[0].layer).to eq :register
      end
    end

    specify '#register_file/#registerは混ぜて使うことができる' do
      expect {
        input_data.register_file {}
        input_data.register {}
        input_data.register {}
        input_data.register_file {}
      }.to change { input_data.children.size }.from(0).to(4)

      expect(input_data.children.map(&:layer)).to match [
        :register_file, :register, :register, :register_file
      ]
    end
  end

  context '階層がregister_fileの場合' do
    let(:input_data) do
      create_input_data(:register_file)
    end

    describe '#register_file' do
      it '子入力データを追加する' do
        expect {
          input_data.register_file {}
        }.to change { input_data.children.size }.from(0).to(1)
      end

      specify '追加される子入力データの階層はregister_fileである' do
        input_data.register_file {}
        expect(input_data.children[0].layer).to eq :register_file
      end
    end

    describe '#register' do
      it '子入力データを追加する' do
        expect {
          input_data.register {}
        }.to change { input_data.children.size }.from(0).to(1)
      end

      specify '追加される子入力データの階層はregisterである' do
        input_data.register {}
        expect(input_data.children[0].layer).to eq :register
      end
    end

    specify '#register_file/#registerは混ぜて使うことができる' do
      expect {
        input_data.register_file {}
        input_data.register {}
        input_data.register {}
        input_data.register_file {}
      }.to change { input_data.children.size }.from(0).to(4)

      expect(input_data.children.map(&:layer)).to match [
        :register_file, :register, :register, :register_file
      ]
    end
  end

  context '階層がregisterの場合' do
    let(:input_data) do
      create_input_data(:register)
    end

    describe '#bit_field' do
      it '子入力データを追加する' do
        expect {
          input_data.bit_field {}
        }.to change { input_data.children.size }.from(0).to(1)
      end

      specify '追加される子入力データの階層はbit_fieldである' do
        input_data.bit_field {}
        expect(input_data.children[0].layer).to eq :bit_field
      end
    end
  end

  context '階層がbit_fieldの場合' do
    let(:input_data) do
      create_input_data(:bit_field)
    end

    it '子入力データを追加できない' do
      expect {
        input_data.child(:foo)
      }.to raise_error NoMethodError
    end
  end

  specify 'configurationオブジェクトを参照できる' do
    cfg = double('configuration', foo: 0, bar: 1, baz: 2, qux: 3, quu: 4)
    values = []

    create_input_data(:root, cfg).instance_eval do
      values << configuration.foo
      register_block do
        values << configuration.bar
        register_file do
          values << configuration.baz
          register do
            values << configuration.qux
            bit_field do
              values << configuration.quu
            end
          end
        end
      end
    end

    expect(values).to match([0, 1, 2, 3, 4])
  end
end
