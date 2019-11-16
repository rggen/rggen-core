# frozen_string_literal: true

RSpec.describe RgGen::Core::Base::Component do
  describe '#component_name' do
    let(:base_name) { 'component' }

    let(:component) { described_class.new(base_name) }

    context '階層情報を取得できない場合' do
      it 'コンポーネント名として、基本名を返す' do
        expect(component.component_name).to eq base_name
      end
    end

    context '階層情報を取得できる場合' do
      it '階層情報を含む、コンポーネント名を返す' do
        allow(component).to receive(:hierarchy).and_return(:foo)
        expect(component.component_name).to eq 'foo@component'
      end
    end
  end

  describe '#parent' do
    let(:parent) { described_class.new('parent') }
    let(:component) { described_class.new('component', parent) }

    it '親オブジェクトを返す' do
      expect(component.parent).to eql parent
    end
  end

  describe '#component_index' do
    let(:parent) { described_class.new('parent') }

    let(:components) do
      Array.new(3) do
        described_class.new('component', parent).tap(&parent.method(:add_child))
      end
    end

    it '親コンポーネント内での通し番号を返す' do
      expect(components[0].component_index).to eq 0
      expect(components[1].component_index).to eq 1
      expect(components[2].component_index).to eq 2
    end

    context '親コンポーネントを持たない場合' do
      it '0を返す' do
        expect(parent.component_index).to eq 0
      end
    end
  end

  describe '#need_children?' do
    let(:components) do
      [
        described_class.new('component'),
        described_class.new('component') { |c| c.need_no_children }
      ]
    end

    it '子コンポーネントが必要かどうかを返す' do
      expect(components[0].need_children?).to be_truthy
      expect(components[1].need_children?).to be_falsey
    end
  end

  describe '#add_child' do
    let(:children) { Array.new(2) { described_class.new('component', component) } }

    before do
      children.each { |c| component.add_child(c) }
    end

    context '子コンポーネントを必要とする場合' do
      let(:component) { described_class.new('component') }

      it '子オブジェクトを追加する' do
        expect(component.children).to match [eql(children[0]), eql(children[1])]
      end
    end

    context '子コンポーネントを必要としない場合' do
      let(:component) { described_class.new('component') { |c| c.need_no_children } }

      it '子コンポーネントの追加を行わない' do
        expect(component.children).to be_empty
      end
    end
  end

  describe '#level' do
    let(:parent) { described_class.new('component') }

    context '親オブジェクトがない場合' do
      it '0を返す' do
        expect(parent.level).to eq 0
      end
    end

    context '親オブジェクトがある場合' do
      let(:child) { described_class.new('component', parent) }
      let(:grandchild) { described_class.new('component', child) }

      it 'parent.level + 1を返す' do
        expect(child.level).to eq 1
        expect(grandchild.level).to eq 2
      end
    end
  end

  describe '#add_feature' do
    let(:component) { described_class.new('component') }

    let(:features) do
      [:foo, :bar].each_with_object({}) do |feature_name, hash|
        hash[feature_name] = Object.new.tap do |feature|
          allow(feature).to receive(:feature_name).and_return(feature_name)
        end
      end
    end

    it 'フィーチャーをコンポーネントに追加する' do
      features.each_value { |feature| component.add_feature(feature) }
      expect(component.features).to match [equal(features[:foo]), equal(features[:bar])]
    end

    specify '追加したフィーチャーは、フィーチャー名で参照できる' do
      features.each_value { |feature| component.add_feature(feature) }
      expect(component.feature(:foo)).to equal features[:foo]
      expect(component.feature(:bar)).to equal features[:bar]
    end
  end
end
