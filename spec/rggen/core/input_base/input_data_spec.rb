require 'spec_helper'

module RgGen::Core::InputBase
  describe InputData do
    matcher :have_value do |name, value = nil, position = nil|
      match do |data|
        @actual = data[name]
        return false unless @actual
        return false unless InputValue === @actual
        return false if value && @actual.value != value
        return false if position && !match_position?(@actual.position, position)
        true
      end

      failure_message do
        if !@actual
          "no such value included: #{name}"
        elsif position
          "expected to have value[#{name}]: #{value.inspect} (position: #{position}) " \
          "but got #{@actual.value.inspect} (position: #{@actual.position})"
        elsif value
          "expected to have value[#{name}]: #{value.inspect} but got #{@actual.value.inspect}"
        end
      end

      failure_message_when_negated do
        "expect not to have value[#{name}]"
      end

      def match_position?(actual_position, expected_position)
        if [actual_position, expected_position].all? { |position|
          position.kind_of?(Thread::Backtrace::Location)
        }
          actual_position.to_s == expected_position.to_s
        else
          actual_position == expected_position
        end
      end
    end

    let(:foo_values) { { foo_0: 0, foo_1: 1, foo_2: 2} }

    let(:bar_values) { { bar_0: 3, bar_1: 4, bar_2: 5} }

    let(:baz_values) { { baz_0: 6, baz_1: 7, baz_2: 8} }

    let(:valid_value_list) { {
      foo: foo_values.keys, bar: bar_values.keys, baz: baz_values.keys
    } }

    let(:position) { Struct.new(:x, :y).new(0, 1) }

    def input_value(value)
      InputValue.new(value, position)
    end

    describe "value/#[]=" do
      let(:foo_data) { InputData.new(:foo, valid_value_list) }

      it "インスタンス時に指定した名前を持つ入力値を設定する" do
        foo_data.value :foo_0, foo_values[:foo_0]
        foo_data.value :foo_1, foo_values[:foo_1], position
        foo_data.value :foo_2, input_value(foo_values[:foo_2])

        expect(foo_data).to have_value :foo_0, foo_values[:foo_0]
        expect(foo_data).to have_value :foo_1, foo_values[:foo_1], position
        expect(foo_data).to have_value :foo_2, foo_values[:foo_2], position
      end

      it "入力値名が文字列でも入力値を設定できる" do
        foo_data.value 'foo_0', foo_values[:foo_0]
        expect(foo_data).to have_value :foo_0, foo_values[:foo_0]
      end

      it "インスタンス時に指定した名前を持たない入力値は設定しない" do
        foo_data.value :bar_0, bar_values[:bar_0]
        foo_data.value :qux_0, 0

        expect(foo_data).not_to have_value :bar_0
        expect(foo_data).not_to have_value :qux_0
      end

      specify "#[]=でも同様に設定できる" do
        foo_data[:foo_0] = foo_values[:foo_0]
        foo_data[:foo_1, position] = foo_values[:foo_1]
        foo_data[:foo_2] = input_value(foo_values[:foo_2])

        expect(foo_data).to have_value :foo_0, foo_values[:foo_0]
        expect(foo_data).to have_value :foo_1, foo_values[:foo_1], position
        expect(foo_data).to have_value :foo_2, foo_values[:foo_2], position
      end
    end

    describe "#values" do
      let(:foo_data) { InputData.new(:foo, valid_value_list) }

      context "入力値列が与えられた場合" do
        before do
          foo_data.values foo_0: foo_values[:foo_0]
          foo_data.values foo_1: foo_values[:foo_1], foo_2: foo_values[:foo_2]
        end

        it "入力値を設定する" do
          expect(foo_data).to  have_value(:foo_0, foo_values[:foo_0]).
                           and have_value(:foo_1, foo_values[:foo_1]).
                           and have_value(:foo_2, foo_values[:foo_2])
        end
      end

      context "無引数の場合" do
        let(:values) { [] }

        before do
          allow(InputValue).to receive(:new).and_wrap_original do |m, *args|
            m.call(*args).tap { |v| values << v }
          end
        end

        before do
          foo_data.values foo_0: foo_values[:foo_0], foo_1: foo_values[:foo_1]
        end

        it "入力値のハッシュを返す" do
          expect(foo_data.values).to match foo_0: equal(values[0]), foo_1: equal(values[1])
        end
      end
    end

    describe "セッターメソッド" do
      let(:foo_data) { InputData.new(:foo, valid_value_list) }

      let(:locations) { [] }

      before do
        foo_data.foo_0 foo_values[:foo_0]; locations << caller_locations(0).first
        foo_data.foo_1 foo_values[:foo_1], position
        foo_data.foo_2 input_value(foo_values[:foo_2])
      end

      specify "入力値名のセッターメソッドを持つ" do
        expect(foo_data).to have_value :foo_0, foo_values[:foo_0], locations[0]
        expect(foo_data).to have_value :foo_1, foo_values[:foo_1], position
        expect(foo_data).to have_value :foo_2, foo_values[:foo_2], position
      end

      specify "positionが未指定の場合、呼び出し元の場所をpositionとする" do
        expect(foo_data).to have_value :foo_0, foo_values[:foo_0], locations[0]
      end
    end

    describe "#child" do
      let(:foo_data) { InputData.new(:foo, valid_value_list) }

      it "子入力データを自身に追加する" do
        expect {
          foo_data.child(:bar)
        }.to change {
          foo_data.children
        }.from(be_empty).to(match([be_instance_of(InputData)]))
      end

      it "生成した子入力データを返す" do
        bar_data = foo_data.child(:bar)
        expect(bar_data).to be foo_data.children[0]
      end

      context "入力値を与えた場合" do
        before do
          foo_data.child(:bar, bar_0: bar_values[:bar_0], bar_1: bar_values[:bar_1])
          foo_data.child(:bar, bar_2: bar_values[:bar_2])
        end

        it "子入力データに設定する" do
          expect(foo_data.children[0]).to have_value(:bar_0, bar_values[:bar_0]).and have_value(:bar_1, bar_values[:bar_1])
          expect(foo_data.children[1]).to have_value(:bar_2, bar_values[:bar_2])
        end
      end

      context "ブロックが与えられた場合" do
        before do
          foo_data.child(:bar) do
            value :bar_0, 3
            values bar_1: bar_values[:bar_1]
            bar_2 bar_values[:bar_2]; locations << caller_locations(0).first

            child(:baz) do
              value :baz_0, 6
              values baz_1: baz_values[:baz_1]
              baz_2 baz_values[:baz_2]; locations << caller_locations(0).first
            end
          end
        end

        let(:bar_data) { foo_data.children[0] }

        let(:baz_data) { bar_data.children[0] }

        let(:locations) { [] }

        it "ブロックを実行し、入力データの組み立てを行う" do
          expect(bar_data).to  have_value(:bar_0, bar_values[:bar_0]).
                           and have_value(:bar_1, bar_values[:bar_1]).
                           and have_value(:bar_2, bar_values[:bar_2], locations[0])
          expect(baz_data).to  have_value(:baz_0, baz_values[:baz_0]).
                           and have_value(:baz_1, baz_values[:baz_1]).
                           and have_value(:baz_2, baz_values[:baz_2], locations[1])
        end
      end

      describe "入力値名リスト" do
        before do
          foo_data.child(:bar, foo_0: foo_values[:foo_0], bar_0: bar_values[:bar_0], baz_0: baz_values[:baz_0])
          foo_data.children[0].child(:baz, foo_1: foo_values[:foo_1], bar_1: bar_values[:bar_1], baz_1: baz_values[:baz_1])
        end

        let(:bar_data) { foo_data.children[0] }

        let(:baz_data) { bar_data.children[0] }

        specify "子入力データに引き継がれる" do
          aggregate_failures do
            expect(bar_data).to have_value :bar_0, bar_values[:bar_0]
            expect(bar_data).not_to have_value :foo_0
            expect(bar_data).not_to have_value :baz_0
          end

          aggregate_failures do
            expect(baz_data).to have_value :baz_1, bar_values[:baz_1]
            expect(baz_data).not_to have_value :foo_1
            expect(baz_data).not_to have_value :bar_1
          end
        end
      end
    end

    describe "#load_file" do
      let(:foo_data) { InputData.new(:foo, valid_value_list) }

      let(:bar_data) { foo_data.children[0] }

      let(:foo_rb) do
        <<'CODE'
value :foo_0, :foo_0
foo_1 :foo_1
child :bar do
  load_file 'bar.rb'
end
CODE
      end

      let(:bar_rb) do
        <<'CODE'
value :bar_0, :bar_0

bar_1 :bar_1
CODE
      end

      let(:position_foo_1) { foo_data[:foo_1].position }

      let(:position_bar_1) { bar_data[:bar_1].position }

      before do
        allow(File).to receive(:binread).and_call_original
        allow(File).to receive(:binread).with('foo.rb').once.and_return(foo_rb)
        allow(File).to receive(:binread).with('bar.rb').once.and_return(bar_rb)
      end

      before do
        foo_data.load_file('foo.rb')
      end

      it "フィアルを読み込んで、自身の組み立てを行う" do
        expect(foo_data).to  have_value(:foo_0, :foo_0).
                         and have_value(:foo_1, :foo_1)
        expect(bar_data).to  have_value(:bar_0, :bar_0).
                         and have_value(:bar_1, :bar_1)
      end

      it "読み出し元のファイルの位置情報がInputValue#positionに記録される" do
        expect(position_foo_1).to have_attributes(path: 'foo.rb', lineno: 2)
        expect(position_bar_1).to have_attributes(path: 'bar.rb', lineno: 3)
      end

      context "指定したファイルが存在しない場合" do
        it "RgGen::LoadErrorを起こす" do
          expect {
            foo_data.load_file('baz.rb')
          }.to raise_error RgGen::Core::LoadError, 'cannot load such file -- baz.rb'
        end
      end
    end
  end
end