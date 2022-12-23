# frozen_string_literal: true

RSpec.describe RgGen::Core::InputBase::Component do
  describe '#add_feature' do
    let(:component) { described_class.new(nil, 'component', nil) }

    let(:features) do
      [
        Class.new(RgGen::Core::InputBase::Feature) { property :foo, default: :foo; property :bar, default: :bar; }
          .new(:feature_0, nil, component),
        Class.new(RgGen::Core::InputBase::Feature) { property :baz, default: :baz }
          .new(:feature_1, nil, component),
        Class.new(RgGen::Core::InputBase::Feature) { property :qux, body: ->(v, vv:, &b) { v + vv + b.call } }
          .new(:feature_2, nil, component)
      ]
    end

    specify 'フィーチャーの追加後、自身をレシーバとして、配下のフィーチャーのフィールドにアクセスできる' do
      features.each do |feature|
        component.add_feature(feature)
      end

      expect(features[0]).to receive(:foo).and_call_original
      expect(features[0]).to receive(:bar).and_call_original
      expect(features[1]).to receive(:baz).and_call_original
      expect(features[2]).to receive(:qux).and_call_original

      expect(component.foo).to eq :foo
      expect(component.bar).to eq :bar
      expect(component.baz).to eq :baz
      expect(component.qux(1, vv: 2) { 3 } ).to eq 6
    end
  end

  describe '#document_only?' do
    let(:components) do
      [
        described_class.new(nil, 'component', nil),
        described_class.new(nil, 'component', nil) { |c| c.document_only }
      ]
    end

    it 'ドキュメント用のコンポーネントかどうかを示す' do
      expect(components[0]).not_to be_document_only
      expect(components[1]).to be_document_only
    end
  end

  describe '#properties' do
    let(:component) { described_class.new(nil, 'component', nil) }

    let(:features) do
      [
        Class.new(RgGen::Core::InputBase::Feature) { property :foo; property :bar}
          .new(:feature_0, nil, component),
        Class.new(RgGen::Core::InputBase::Feature) { property :baz }
          .new(:feature_1, nil, component)
      ]
    end

    before do
      features.each { |feature| component.add_feature(feature) }
    end

    it '配下のフィーチャーが持つプロパティの一覧を返す' do
      expect(component.properties).to match [:foo, :bar, :baz]
    end
  end

  describe '#post_build' do
    let(:foo_component) do
      described_class.new(nil, 'component', nil)
    end

    let(:bar_component) do
      described_class.new(foo_component, 'component', nil)
    end

    let(:features) do
      [foo_component, bar_component].flat_map.with_index do |component, i|
        Array.new(2) do |j|
          feature = RgGen::Core::InputBase::Feature.new("feature_#{i}_#{j}", nil, component)
          component.add_feature(feature)
          feature
        end
      end
    end

    it '直下のフィーチャーの#post_buildを呼んで、組み立て後の後処理を行う' do
      expect(features[0]).to receive(:post_build)
      expect(features[1]).to receive(:post_build)
      expect(features[2]).not_to receive(:post_build)
      expect(features[3]).not_to receive(:post_build)
      foo_component.post_build
    end
  end

  describe '#verify' do
    let(:foo_component) { described_class.new(nil, 'component', nil) }

    let(:bar_components) do
      Array.new(2) do
        component = described_class.new(foo_component, 'component', nil)
        foo_component.add_child(component)
        component
      end
    end

    let(:baz_components) do
      bar_components.flat_map do |bar_component|
        Array.new(2) do
          component = described_class.new(bar_component, 'component', nil)
          bar_component.add_child(component)
          component
        end
      end
    end

    let(:features) do
      [foo_component, *bar_components, *baz_components].flat_map.with_index do |component, i|
        Array.new(2) do |j|
          feature = RgGen::Core::InputBase::Feature.new("feature_#{i}_#{j}", nil, component)
          component.add_feature(feature)
          feature
        end
      end
    end

    context '検証範囲が:componentの場合' do
      it '配下のフィーチャーの#verifyを呼び出して、自身の検証を行う' do
        [*bar_components, *baz_components].each do |component|
          expect(component).not_to receive(:verify)
        end
        features.each_with_index do |feature, i|
          if [0, 1].include?(i)
            expect(feature).to receive(:verify).with(:component)
          else
            expect(feature).not_to receive(:verify)
          end
        end
        foo_component.verify(:component)
      end
    end

    it '配下の全コンポーネント、フィーチャーの#verifyを呼び出して、全体検証を行う' do
      [*bar_components, *baz_components].each do |component|
        expect(component).to receive(:verify).with(:all).and_call_original
      end
      features.each do |feature|
        expect(feature).to receive(:verify).with(:all).and_call_original
      end
      foo_component.verify(:all)
    end
  end

  describe '#printables' do
    def create_feature(component, feature_name, &body)
      feature =
        Class.new(RgGen::Core::InputBase::Feature, &body)
          .new(feature_name, nil, component)
      component.add_feature(feature)
      feature
    end

    let(:component) { described_class.new(nil, 'component', nil) }

    let(:child_component) do
      described_class.new(component, 'component', nil).tap { |child| component.add_child(child) }
    end

    before do
      create_feature(component, :foo) do
        printable(:foo_0) { 'foo_0' }
        printable(:foo_1) { 'foo_1' }
      end
      create_feature(component, :bar)
      create_feature(component, :baz) do
        printable(:baz_0) { 'baz_0' }
        printable(:baz_1) { 'baz_1' }
      end

      create_feature(child_component, :foo) { printable(:foo_0) { 'child foo_0' } }
      create_feature(child_component, :bar) { printable(:bar_0) { 'child bar_0' } }
      create_feature(child_component, :baz) { printable(:baz_0) { 'child baz_0' } }
    end

    it '自身に属するフィーチャーの表示可能オブジェクト一覧を返す' do
      expect(component.printables).to match(foo_0: 'foo_0', foo_1: 'foo_1', baz_0: 'baz_0', baz_1: 'baz_1')
    end
  end
end
