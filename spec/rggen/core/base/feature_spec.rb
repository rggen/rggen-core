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
            def foo ; end
            def bar ; end
          end
        end
      end

      it "特異クラスにヘルパーメソッドを追加する" do
        expect(feature_class.singleton_methods(false)).to contain_exactly :foo, :bar
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
  end
end
