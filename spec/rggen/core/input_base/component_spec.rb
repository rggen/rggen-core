require 'spec_helper'

module RgGen::Core::InputBase
  describe Component do
    describe "#add_feature" do
      let(:component) { Component.new }

      let(:features) do
        [
          Class.new(Feature) { field :foo, default: :foo; field :bar, default: :bar; }.new(component, :feature_0),
          Class.new(Feature) { field :baz, default: :baz }.new(component, :feature_1)
        ]
      end

      specify "アイテムの追加後、自身をレシーバとして、配下のアイテムのフィールドにアクセスできる" do
        features.each do |feature|
          component.add_feature(feature)
        end

        expect(features[0]).to receive(:foo).and_call_original
        expect(features[0]).to receive(:bar).and_call_original
        expect(features[1]).to receive(:baz).and_call_original

        expect(component.foo).to eq :foo
        expect(component.bar).to eq :bar
        expect(component.baz).to eq :baz
      end
    end

    describe "#fields" do
      let(:component) { Component.new }

      let(:features) do
        [
          Class.new(Feature) { field :foo; field :bar}.new(component, :feature_0),
          Class.new(Feature) { field :baz }.new(component, :feature_1)
        ]
      end

      before do
        features.each { |feature| component.add_feature(feature) }
      end

      it "配下のフィーチャーが持つフィールドの一覧を返す" do
        expect(component.fields).to match [:foo, :bar, :baz]
      end
    end

    describe "#validate" do
      let(:foo_component) { Component.new }

      let(:bar_components) do
        Array.new(2) do
          component = Component.new(foo_component)
          foo_component.add_child(component)
          component
        end
      end

      let(:baz_components) do
        bar_components.flat_map do |bar_component|
          Array.new(2) do
            component = Component.new(bar_component)
            bar_component.add_child(component)
            component
          end
        end
      end

      let(:features) do
        [foo_component, *bar_components, *baz_components].flat_map.with_index do |component, i|
          Array.new(2) do |j|
            feature = Feature.new(component, "feature_#{i}_#{j}")
            component.add_feature(feature)
            feature
          end
        end
      end

      it "配下の全コンポーネント、アイテムの検査を行う" do
        [*bar_components, *baz_components].each do |component|
          expect(component).to receive(:validate).and_call_original
        end
        features.each do |feature|
          expect(feature).to receive(:validate).and_call_original
        end
        foo_component.validate
      end
    end
  end
end
