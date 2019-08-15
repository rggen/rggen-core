# frozen_string_literal: true

require  'spec_helper'

module RgGen::Core::Base
  describe Feature do
    let(:component) { Component.new }

    let(:feature_class) { Class.new(Feature) }

    let(:feature_name) { :foo }

    let(:feature) { feature_class.new(component, feature_name) }

    describe "#component" do
      it "オーナーコンポーネントを返す" do
        expect(feature.component).to eql component
      end
    end

    describe "#name" do
      it "フィーチャー名を返す" do
        expect(feature.feature_name).to eq feature_name
      end
    end

    describe ".define_helpers" do
      before do
        feature_class.class_exec do
          define_helpers do
            def foo ; :foo; end
            def bar ; :bar; end
          end
        end
      end

      it "特異クラスにヘルパーメソッドを追加する" do
        expect(feature_class.singleton_methods(false)).to contain_exactly :foo, :bar
      end

      specify "#helperヘルパーメソッドを参照できる" do
        expect(feature.instance_eval { helper.foo }).to eq :foo
        expect(feature.instance_eval { helper.bar }).to eq :bar
      end
    end

    describe "#available?" do
      context "通常の場合" do
        it "使用可能であることを示す" do
          expect(feature).to be_available
        end
      end

      context ".available?で#available?が再定義された場合" do
        before do
          feature_class.class_exec do
            available? { false }
          end
        end

        it "available?に与えたブロックの評価結果を返す" do
          expect(feature).not_to be_available
        end
      end
    end

    describe '#printables' do
      context '.printableに表示可能オブジェクト名のみ与えられた場合' do
        before do
          feature_class.class_exec do
            printable :foo
            printable :bar
            def foo; 1; end
            def bar; 2; end
          end
        end

        it '同名のメソッドの戻り値を表示可能オブジェクトとして返す' do
          expect(feature.printables).to match([[:foo, 1], [:bar, 2]])
        end
      end

      context '.printableにブロックも与えられた場合' do
        before do
          feature_class.class_exec do
            printable(:foo) { 2 * foo }
            printable(:bar) { 2 * bar }
            def foo; 1; end
            def bar; 2; end
          end
        end

        it 'ブロックを評価し、表示可能オブジェクトとして返す' do
          expect(feature.printables).to match([[:foo, 2], [:bar, 4]])
        end
      end

      context '継承された場合' do
        before do
          feature_class.class_exec do
            printable(:foo)
            printable(:bar) { 2 * bar }
            def foo; 1; end
            def bar; 2; end
          end
        end

        specify '.printableで指定された表示可能オブジェクトは子クラスに引き継がれる' do
          child_feature = Class.new(feature_class).new(component, feature_name)
          expect(child_feature.printables).to match([[:foo, 1], [:bar, 4]])
        end

        specify '子クラスでのブロックの再指定は、親クラスに影響しない' do
          Class.new(feature_class) do
            printable(:foo) { 3 * foo }
            printable(:bar) { 3 * bar }
          end
          expect(feature.printables).to match([[:foo, 1], [:bar, 4]])
        end
      end
    end

    describe '#printable?' do
      context '.printableでブロックが指定されている場合' do
        before do
          feature_class.class_exec { printable(:foo) { 'foo' } }
        end

        it '真を返す' do
          expect(feature).to be_printable
        end
      end

      context '.printableでブロックが指定されていない場合' do
        it '偽を返す' do
          expect(feature).not_to be_printable
        end
      end
    end
  end
end
