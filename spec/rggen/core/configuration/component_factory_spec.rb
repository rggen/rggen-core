require 'spec_helper'

module RgGen::Core::Configuration
  describe ComponentFactory do
    def define_item(item_name)
      Class.new(Item) do
        field item_name
        build { |value| instance_variable_set(item_name.variablize, value) }
      end
    end

    let(:foo_item) { define_item(:foo) }
    let(:foo_item_factory) { ItemFactory.new(:foo) { |f| f.target_item foo_item } }

    let(:bar_item) { define_item(:bar) }
    let(:bar_item_factory) { ItemFactory.new(:baz) { |f| f.target_item bar_item } }

    let(:baz_item) { define_item(:baz) }
    let(:baz_item_factory) { ItemFactory.new(:baz) { |f| f.target_item baz_item } }

    let(:item_factories) do
      { foo: foo_item_factory, bar: bar_item_factory, baz: baz_item_factory }
    end

    let(:factory) do
      ComponentFactory.new do |f|
        f.root_factory
        f.target_component Component
        f.item_factories item_factories
        f.loaders [JSONLoader]
      end
    end

    describe "#create" do
      let(:item_values) do
        { foo: rand(99), bar: rand(99), baz: rand(99) }
      end

      let(:file_contents) { JSON.dump(item_values) }

      let(:file) { 'foo.json' }

      let(:configuration) { factory.create([file]) }

      before do
        allow(File).to receive(:readable?).with(file).and_return(true)
        allow(File).to receive(:binread).with(file).and_return(file_contents)
      end

      before do
        expect(Component).to receive(:new).and_call_original
      end

      it "コンフィグレーションコンポーネント生成と組み立てを行う" do
        expect(configuration).to have_attributes(item_values)
      end
    end
  end
end
