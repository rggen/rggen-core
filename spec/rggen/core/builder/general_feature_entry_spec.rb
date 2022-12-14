# frozen_string_literal: true

RSpec.describe RgGen::Core::Builder::GeneralFeatureEntry do
  let(:feature_name) { :feature }

  let(:feature_base) { RgGen::Core::InputBase::Feature }

  let(:factory_base) do
    Class.new(RgGen::Core::InputBase::FeatureFactory) do
      def create(*args)
        create_feature(*args)
      end
    end
  end

  let(:component) { RgGen::Core::InputBase::Component.new(nil, :component, nil) }

  let(:feature_registry) { double('feature_registry') }

  def create_entry(context = nil, &body)
    entry = described_class.new(feature_registry, feature_name)
    entry.setup(feature_base, factory_base, context, &body)
    entry
  end

  describe 'ファクトリーの定義' do
    specify '#build_factoryでエントリー生成時に指定したファクトリ継承したファクトリを生成する' do
      entry = create_entry
      factory = entry.build_factory(nil)
      expect(factory).to be_kind_of factory_base
      expect(factory).not_to be_instance_of factory_base
    end

    specify '#define_factory/#factoryでファクトリを定義できる' do
      entry = create_entry do
        define_factory { def foo; 'foo'; end }
        factory { def bar; 'bar'; end }
      end
      factory = entry.build_factory(nil)

      expect(factory.foo).to eq 'foo'
      expect(factory.bar).to eq 'bar'
    end
  end

  describe 'フィーチャーの定義' do
    specify '生成したファクトリでエントリー生成時に指定したフィーチャーを継承したフィーチャーを生成できる' do
      factory = create_entry.build_factory(nil)
      feature = factory.create(component, nil)
      expect(feature).to be_kind_of feature_base
      expect(feature).not_to be_instance_of feature_base
    end

    specify '#define_feature/#featureでフィーチャーを定義できる' do
      entry = create_entry do
        define_feature { def foo; 'foo'; end }
        feature { def bar; 'bar'; end }
      end
      feature = entry.build_factory(nil).create(component, nil)

      expect(feature.foo).to eq 'foo'
      expect(feature.bar).to eq 'bar'
    end

    specify 'エントリー生成時に指定した名称が、フィーチャーの名称になる' do
      factory = create_entry.build_factory(nil)
      feature = factory.create(component, nil)
      expect(feature.feature_name).to eq feature_name
    end
  end

  describe '共通コンテキストの設定' do
    let(:shared_context) { Object.new }

    specify 'エントリー/ファクトリー/フィーチャーは指定された共通コンテキストを持つ' do
      entry = create_entry(shared_context)
      expect(entry.shared_context).to be shared_context

      factory = create_entry(shared_context).build_factory(nil)
      expect(factory.shared_context).to be shared_context

      feature = factory.create(component, nil)
      expect(feature.shared_context).to be shared_context

      feature = factory.create(component, nil)
      expect(feature.shared_context).to be shared_context
    end
  end
end
