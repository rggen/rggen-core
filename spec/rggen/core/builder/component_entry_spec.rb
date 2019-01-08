require 'spec_helper'

module RgGen::Core::Builder
  describe ComponentEntry do
    let(:base_component) { RgGen::Core::InputBase::Component }

    let(:component_factory) do
      Class.new(RgGen::Core::InputBase::ComponentFactory) do
        def create_component(parent, *_, &block)
          @target_component.new(parent, &block)
        end
      end
    end

    let(:base_feature) do
      Class.new(RgGen::Core::InputBase::Feature) do
        build { |v| @v = v }
      end
    end

    let(:feature_factory) do
      RgGen::Core::InputBase::FeatureFactory
    end

    let(:parent) do
      RgGen::Core::InputBase::Component.new(nil)
    end

    def create_entry
      entry = ComponentEntry.new
      block_given? && yield(entry)
      entry
    end

    it "#component/#component_facotryで指定されたコンポーネントを生成するファクトリを生成する" do
      entry = create_entry do |e|
        e.component base_component
        e.component_factory component_factory
      end

      factory = entry.build_factory
      component = factory.create(parent)
      expect(component).to be_kind_of base_component
    end

    context "コンポーネントの指定時に、ブロックが与えられた場合" do
      it "ブロックを使って、コンポーネントの定義を行う" do
        entry = create_entry do |e|
          e.component(base_component) do
            def m; 'foo !'; end
          end
          e.component_factory(component_factory) do
            def m; 'foo !!'; end
          end
        end

        factory = entry.build_factory
        component = factory.create(parent)

        expect(component.m).to eq 'foo !'
        expect(factory.m).to eq 'foo !!'
      end
    end

    context "#base_feature/#feature_facotryでフィーチャーの指定がない場合" do
      specify "生成されるコンポーネントはフィーチャーを持たない" do
        entry = create_entry do |e|
          e.component base_component
          e.component_factory component_factory
        end

        factory = entry.build_factory
        component = factory.create(parent)
        expect(component.features).to be_empty

        entry = create_entry do |e|
          e.component base_component
          e.component_factory component_factory
          e.base_feature base_feature
        end

        factory = entry.build_factory
        component = factory.create(parent)
        expect(component.features).to be_empty

        entry = create_entry do |e|
          e.component base_component
          e.component_factory component_factory
          e.feature_factory feature_factory
        end

        factory = entry.build_factory
        component = factory.create(parent)
        expect(component.features).to be_empty
      end
    end

    context "#base_feature/#feature_facotryでフィーチャーの指定がある場合" do
      let(:input_data) do
        RgGen::Core::InputBase::InputData.new([[:foo, :bar]]) do |data|
          data.foo(rand(99))
          data.bar(rand(99))
        end
      end

      specify "生成されるコンポーネントはフィーチャーを持つ" do
        entry = create_entry do |e|
          e.component base_component
          e.component_factory component_factory
          e.base_feature base_feature
          e.feature_factory feature_factory
        end
        entry.feature_registry.tap do |registry|
          registry.define_simple_feature(nil, :foo) do
            property(:foo) { @v }
          end
          registry.define_simple_feature(nil, :bar) do
            property(:bar) { @v }
          end
          registry.enable([:foo, :bar])
        end

        factory = entry.build_factory
        component = factory.create(parent, input_data)

        expect(component.foo).to eq input_data[:foo].value
        expect(component.bar).to eq input_data[:bar].value
      end

      context "フィーチャーの指定時に、ブロックが与えられた場合" do
        it "ブロックを使って、フィーチャーの定義を行う" do
          entry = create_entry do |e|
            e.component base_component
            e.component_factory component_factory
            e.base_feature base_feature do
              def m; @v; end
            end
            e.feature_factory feature_factory do
              convert_value { |v| 2 * v }
            end
          end
          entry.feature_registry.tap do |registry|
            registry.define_simple_feature(nil, :foo) do
              property(:foo, forward_to: :m)
            end
            registry.define_simple_feature(nil, :bar) do
              property(:bar, forward_to: :m)
            end
            registry.enable([:foo, :bar])
          end

          factory = entry.build_factory
          component = factory.create(parent, input_data)

          expect(component.foo).to eq 2 * input_data[:foo].value
          expect(component.bar).to eq 2 * input_data[:bar].value
        end
      end
    end
  end
end
