require 'spec_helper'

module RgGen::Core::Builder
  describe SimpleFeatureEntry do
    let(:feature_name) { :foo_feature }

    let(:factory_class) do
      Class.new(RgGen::Core::InputBase::FeatureFactory) do
        def create(*args)
          create_feature(*args)
        end
      end
    end

    let(:feature_base_class) { RgGen::Core::InputBase::Feature }

    let(:component) { RgGen::Core::InputBase::Component.new(nil) }

    def create_entry(shared_context, &body)
      SimpleFeatureEntry.new(feature_name, factory_class, feature_base_class, shared_context, body)
    end

    describe "#build_factory" do
      it "エントリー生成時に指定したファクトリを返す" do
        entry = create_entry(nil)
        factory = entry.build_factory
        expect(factory).to be_instance_of factory_class
      end
    end

    specify "#build_facotryで生成したファクトリは、定義したフィーチャーを生成する" do
      entry = create_entry(nil) { def foo; 'foo!'; end }
      factory = entry.build_factory
      entry = factory.create(component)

      expect(entry).to be_kind_of feature_base_class
      expect(entry.foo).to eq 'foo!'
    end

    specify "生成されるフィーチャーは、エントリー生成時に指定されたフィーチャー名を持つ" do
      entry = create_entry(nil)
      feature = entry.build_factory.create(component)
      expect(feature.name).to eq feature_name
    end

    context "共有コンテキストが与えられた場合" do
      let(:shared_context) { Object.new }

      specify "生成されるフィーチャーは共有コンテキストを持つ" do
        entry = create_entry(shared_context)
        feature = entry.build_factory.create(component)
        expect(feature.send(:shared_context)).to be shared_context
      end
    end
  end
end
