require 'spec_helper'

module RgGen::Core::Base
  describe Component do
    describe "#parent" do
      let(:parent) { Component.new }
      let(:component) { Component.new(parent) }

      it "親オブジェクトを返す" do
        expect(component.parent).to eql parent
      end
    end

    describe "#need_children?" do
      let(:components) do
        [
          Component.new,
          Component.new { |c| c.need_no_children }
        ]
      end

      it "子コンポーネントが必要かどうかを返す" do
        expect(components[0].need_children?).to be_truthy
        expect(components[1].need_children?).to be_falsey
      end
    end

    describe "#add_child" do
      let(:children) { Array.new(2) { Component.new(component) } }

      before do
        children.each { |c| component.add_child(c) }
      end

      context "子コンポーネントを必要とする場合" do
        let(:component) { Component.new }

        it "子オブジェクトを追加する" do
          expect(component.children).to match [eql(children[0]), eql(children[1])]
        end
      end

      context "子コンポーネントを必要としない場合" do
        let(:component) { Component.new { |c| c.need_no_children } }

        it "子コンポーネントの追加を行わない" do
          expect(component.children).to be_empty
        end
      end
    end

    describe "#level" do
      let(:parent) { Component.new }

      context "親オブジェクトがない場合" do
        it "0を返す" do
          expect(parent.level).to eq 0
        end
      end

      context "親オブジェクトがある場合" do
        let(:child) { Component.new(parent) }
        let(:grandchild) { Component.new(child) }

        it "parent.level + 1を返す" do
          expect(child.level     ).to eq 1
          expect(grandchild.level).to eq 2
        end
      end
    end

    describe "#add_feature" do
      let(:component) { Component.new }

      let(:features) do
        [:foo, :bar].each_with_object({}) do |feature_name, hash|
          hash[feature_name] = Object.new.tap do |feature|
            allow(feature).to receive(:name).and_return(feature_name)
          end
        end
      end

      it "フィーチャーをコンポーネントに追加する" do
        features.each_value { |feature| component.add_feature(feature) }
        expect(component.features).to match [equal(features[:foo]), equal(features[:bar])]
      end

      specify "追加したフィーチャーは、フィーチャー名で参照できる" do
        features.each_value { |feature| component.add_feature(feature) }
        expect(component.feature(:foo)).to equal features[:foo]
        expect(component.feature(:bar)).to equal features[:bar]
      end
    end
  end
end
