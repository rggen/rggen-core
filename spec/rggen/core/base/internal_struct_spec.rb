# frozen_string_literal: true

require  'spec_helper'

module RgGen::Core::Base
  describe InternalStruct do
    matcher :have_struct do |struct_name, members|
      match do |o|
        s = o.send(struct_name)
        s < Struct && values_match?(s.members, members)
      end
    end

    def define_class(parent_class = Object, &body)
      Class.new(parent_class) do
        extend InternalStruct
        class_exec(&body)
      end
    end

    describe ".define_struct" do
      let(:klass) do
        define_class do
          define_struct :foo, [:foo_0]
          define_struct :bar, [:bar_0, :bar_1]
          define_struct :baz, [:baz_0, :baz_1] do
            def baz_0_baz_1
              baz_0 + baz_1
            end
          end
        end
      end

      let(:object) { klass.new }

      let(:baz_struct) do
        object.instance_eval { baz.new(1, 2) }
      end

      it "引数で与えた名前と要素を持つ構造体を定義する" do
        expect(object).to have_struct :foo, [:foo_0]
        expect(object).to have_struct :bar, [:bar_0, :bar_1]
        expect(object).to have_struct :baz, [:baz_0, :baz_1]
      end

      it "ブロックを定義した構造体のコンテキストで実行する" do
        expect(baz_struct.baz_0_baz_1).to eq 3
      end

      context "同一名の構造体が定義された場合" do
        before do
          klass.class_exec do
            define_struct :foo, [:foo_0, :foo_1]
          end
        end

        specify "あとの構造体定義が優先される" do
          expect(object).to have_struct :foo, [:foo_0, :foo_1]
        end
      end
    end

    context "継承された場合" do
      let(:grandparent_class) do
        define_class { define_struct :foo, [:foo_0] }
      end

      let(:parent_class) do
        define_class(grandparent_class) { define_struct :bar, [:bar_0] }
      end

      let(:klass) do
        define_class(parent_class) { define_struct :baz, [:baz_0] }
      end

      let(:object) { klass.new }

      specify "定義した構造体は継承される" do
        expect(object).to have_struct :foo, [:foo_0]
        expect(object).to have_struct :bar, [:bar_0]
        expect(object).to have_struct :baz, [:baz_0]
      end
    end
  end
end
