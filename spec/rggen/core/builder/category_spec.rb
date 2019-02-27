# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::Builder
  describe Category do
    let(:category) { Category.new(:a_category) }

    let(:fizz_feature_registry) do
      FeatureRegistry.new(
        RgGen::Core::Configuration::Feature,
        RgGen::Core::Configuration::FeatureFactory
      )
    end

    let(:buzz_feature_registry) do
      FeatureRegistry.new(
        RgGen::Core::Configuration::Feature,
        RgGen::Core::Configuration::FeatureFactory
      )
    end

    before do
      category.add_feature_registry(:fizz, fizz_feature_registry)
      category.add_feature_registry(:buzz, buzz_feature_registry)
    end

    describe "フィーチャーの定義" do
      specify "#add_feature_registry呼び出し時に指定した登録名でフィーチャーを定義できる" do
        expect(fizz_feature_registry).to receive(:define_simple_feature).with(nil, :foo).and_call_original
        expect(buzz_feature_registry).to receive(:define_simple_feature).with(nil, :foo).and_call_original
        category.define_simple_feature(:foo) do
          fizz {}
          buzz {}
        end

        expect(fizz_feature_registry).to receive(:define_list_feature).with(nil, :bar).and_call_original
        expect(buzz_feature_registry).to receive(:define_list_feature).with(nil, :bar).and_call_original
        category.define_list_feature(:bar) do
          fizz {}
          buzz {}
        end

        expect(fizz_feature_registry).to receive(:define_list_feature).with(nil, :bar, :bar_0).and_call_original
        expect(buzz_feature_registry).to receive(:define_list_feature).with(nil, :bar, :bar_0).and_call_original
        category.define_list_feature(:bar, :bar_0) do
          fizz {}
          buzz {}
        end
      end

      specify "複数個のフィーチャーを同時に定義できる" do
        expect(fizz_feature_registry).to receive(:define_simple_feature).with(nil, :foo_0).and_call_original
        expect(buzz_feature_registry).to receive(:define_simple_feature).with(nil, :foo_0).and_call_original
        expect(fizz_feature_registry).to receive(:define_simple_feature).with(nil, :foo_1).and_call_original
        expect(buzz_feature_registry).to receive(:define_simple_feature).with(nil, :foo_1).and_call_original
        category.define_simple_feature([:foo_0, :foo_1]) do
          fizz {}
          buzz {}
        end

        expect(fizz_feature_registry).to receive(:define_list_feature).with(nil, :bar_0).and_call_original
        expect(buzz_feature_registry).to receive(:define_list_feature).with(nil, :bar_0).and_call_original
        expect(fizz_feature_registry).to receive(:define_list_feature).with(nil, :bar_1).and_call_original
        expect(buzz_feature_registry).to receive(:define_list_feature).with(nil, :bar_1).and_call_original
        category.define_list_feature([:bar_0, :bar_1]) do
          fizz {}
          buzz {}
        end

        expect(fizz_feature_registry).to receive(:define_list_feature).with(nil, :bar_0, :bar_0_0).and_call_original
        expect(buzz_feature_registry).to receive(:define_list_feature).with(nil, :bar_0, :bar_0_0).and_call_original
        expect(fizz_feature_registry).to receive(:define_list_feature).with(nil, :bar_0, :bar_0_1).and_call_original
        expect(buzz_feature_registry).to receive(:define_list_feature).with(nil, :bar_0, :bar_0_1).and_call_original
        category.define_list_feature(:bar_0, [:bar_0_0, :bar_0_1]) do
          fizz {}
          buzz {}
        end
      end

      context "共有コンテキストが有効な場合" do
        specify "フィーチャー定義時に共有コンテキストが渡される" do
          contexts = []

          allow(fizz_feature_registry).to receive(:define_simple_feature).and_call_original
          allow(buzz_feature_registry).to receive(:define_simple_feature).and_call_original
          category.define_simple_feature(:foo, shared_context: true) do
            fizz {}
            buzz {}
            shared_context { contexts << self }
          end
          expect(fizz_feature_registry).to have_received(:define_simple_feature).with(equal(contexts.last), :foo)
          expect(buzz_feature_registry).to have_received(:define_simple_feature).with(equal(contexts.last), :foo)

          allow(fizz_feature_registry).to receive(:define_list_feature).and_call_original
          allow(buzz_feature_registry).to receive(:define_list_feature).and_call_original
          category.define_list_feature(:bar, shared_context: true) do
            fizz {}
            buzz {}
            shared_context { contexts << self }
          end
          expect(fizz_feature_registry).to have_received(:define_list_feature).with(equal(contexts.last), :bar)
          expect(buzz_feature_registry).to have_received(:define_list_feature).with(equal(contexts.last), :bar)

          category.define_list_feature(:baz) do
            fizz {}
            buzz {}
          end
          allow(fizz_feature_registry).to receive(:define_list_feature).and_call_original
          allow(buzz_feature_registry).to receive(:define_list_feature).and_call_original
          category.define_list_feature(:baz, :baz_0, shared_context: true) do
            fizz {}
            buzz {}
            shared_context { contexts << self }
          end
          expect(fizz_feature_registry).to have_received(:define_list_feature).with(equal(contexts.last), :baz, :baz_0)
          expect(buzz_feature_registry).to have_received(:define_list_feature).with(equal(contexts.last), :baz, :baz_0)
        end

        specify "各共有コンテキストは独立している" do
          contexts = []

          category.define_simple_feature([:foo_0, :foo_1], shared_context: true) do
            shared_context { contexts << self }
          end
          category.define_list_feature([:bar_0, :bar_1], shared_context: true) do
            shared_context { contexts << self }
          end
          category.define_list_feature(:baz) do
            fizz {}
            buzz {}
          end
          category.define_list_feature(:baz, [:baz_0, :baz_1], shared_context: true) do
            shared_context { contexts << self }
          end

          expect(contexts.size).to eq contexts.map(&:object_id).uniq.size
        end
      end
    end

    describe "フィーチャーの有効化" do
      before do
        category.define_simple_feature([:foo_0, :foo_1, :foo_2]) do
          fizz {}
          buzz {}
        end
        category.define_list_feature([:bar_0, :bar_1, :bar_2]) do
          fizz {}
          buzz {}
        end
        category.define_list_feature(:bar_0, [:bar_0_0, :bar_0_1, :bar_0_2, :bar_0_3]) do
          fizz {}
          buzz {}
        end
      end

      specify "#enableで指定したフィーチャーを有効にする" do
        expect(fizz_feature_registry).to receive(:enable).with(:foo_0, nil)
        expect(buzz_feature_registry).to receive(:enable).with(:foo_0, nil)
        category.enable(:foo_0)

        expect(fizz_feature_registry).to receive(:enable).with([:foo_1, :bar_0], nil)
        expect(buzz_feature_registry).to receive(:enable).with([:foo_1, :bar_0], nil)
        category.enable([:foo_1, :bar_0])

        expect(fizz_feature_registry).to receive(:enable).with(:bar_0, :bar_0_0)
        expect(buzz_feature_registry).to receive(:enable).with(:bar_0, :bar_0_0)
        category.enable(:bar_0, :bar_0_0)

        expect(fizz_feature_registry).to receive(:enable).with(:bar_0, [:bar_0_1, :bar_0_2])
        expect(buzz_feature_registry).to receive(:enable).with(:bar_0, [:bar_0_1, :bar_0_2])
        category.enable(:bar_0, [:bar_0_1, :bar_0_2])
      end
    end
  end
end
