# frozen_string_literal: true

RSpec.describe RgGen::Core::Builder::Layer do
  let(:layer) { described_class.new(:foo_layer) }

  let(:fizz_feature_registry) do
    RgGen::Core::Builder::FeatureRegistry.new(
      RgGen::Core::Configuration::Feature,
      RgGen::Core::Configuration::FeatureFactory
    )
  end

  let(:buzz_feature_registry) do
    RgGen::Core::Builder::FeatureRegistry.new(
      RgGen::Core::Configuration::Feature,
      RgGen::Core::Configuration::FeatureFactory
    )
  end

  before do
    layer.add_feature_registry(:fizz, fizz_feature_registry)
    layer.add_feature_registry(:buzz, buzz_feature_registry)
  end

  describe 'フィーチャーの定義' do
    specify '#add_feature_registry呼び出し時に指定した登録名でフィーチャーを定義できる' do
      expect(fizz_feature_registry).to receive(:define_simple_feature).with(:foo).and_call_original
      expect(buzz_feature_registry).to receive(:define_simple_feature).with(:foo).and_call_original
      layer.define_simple_feature(:foo) do
        fizz {}
        buzz {}
      end

      expect(fizz_feature_registry).to receive(:define_simple_feature).with(:bar_0).and_call_original
      expect(buzz_feature_registry).to receive(:define_simple_feature).with(:bar_0).and_call_original
      expect(fizz_feature_registry).to receive(:define_simple_feature).with(:bar_1).and_call_original
      expect(buzz_feature_registry).to receive(:define_simple_feature).with(:bar_1).and_call_original
      layer.define_simple_feature([:bar_0, :bar_1]) do
        fizz {}
        buzz {}
      end

      expect(fizz_feature_registry).to receive(:define_list_feature).with(:baz).and_call_original
      expect(buzz_feature_registry).to receive(:define_list_feature).with(:baz).and_call_original
      layer.define_list_feature(:baz) do
        fizz {}
        buzz {}
      end

      expect(fizz_feature_registry).to receive(:define_list_item_feature).with(:baz, :baz_0).and_call_original
      expect(buzz_feature_registry).to receive(:define_list_item_feature).with(:baz, :baz_0).and_call_original
      layer.define_list_item_feature(:baz, :baz_0) do
        fizz {}
        buzz {}
      end

      expect(fizz_feature_registry).to receive(:define_list_item_feature).with(:baz, :baz_1).and_call_original
      expect(buzz_feature_registry).to receive(:define_list_item_feature).with(:baz, :baz_1).and_call_original
      expect(fizz_feature_registry).to receive(:define_list_item_feature).with(:baz, :baz_2).and_call_original
      expect(buzz_feature_registry).to receive(:define_list_item_feature).with(:baz, :baz_2).and_call_original
      layer.define_list_item_feature(:baz, [:baz_1, :baz_2]) do
        fizz {}
        buzz {}
      end

      expect(fizz_feature_registry).to receive(:define_list_feature).with(:qux_0).and_call_original
      expect(buzz_feature_registry).to receive(:define_list_feature).with(:qux_0).and_call_original
      expect(fizz_feature_registry).to receive(:define_list_feature).with(:qux_1).and_call_original
      expect(buzz_feature_registry).to receive(:define_list_feature).with(:qux_1).and_call_original
      layer.define_list_feature([:qux_0, :qux_1]) do
        fizz {}
        buzz {}
      end
    end

    context '共有コンテキストが有効な場合' do
      specify 'フィーチャー定義時に共有コンテキストが渡される' do
        contexts = []

        allow(fizz_feature_registry).to receive(:define_simple_feature).and_call_original
        allow(buzz_feature_registry).to receive(:define_simple_feature).and_call_original
        layer.define_simple_feature(:foo) do
          fizz {}
          buzz {}
          shared_context { contexts << self }
        end
        expect(fizz_feature_registry).to have_received(:define_simple_feature).with(:foo, equal(contexts.last))
        expect(buzz_feature_registry).to have_received(:define_simple_feature).with(:foo, equal(contexts.last))

        allow(fizz_feature_registry).to receive(:define_list_feature).and_call_original
        allow(buzz_feature_registry).to receive(:define_list_feature).and_call_original
        layer.define_list_feature(:bar) do
          fizz {}
          buzz {}
          shared_context { contexts << self }
        end
        expect(fizz_feature_registry).to have_received(:define_list_feature).with(:bar, equal(contexts.last))
        expect(buzz_feature_registry).to have_received(:define_list_feature).with(:bar, equal(contexts.last))

        layer.define_list_feature(:baz) do
          fizz {}
          buzz {}
        end
        allow(fizz_feature_registry).to receive(:define_list_item_feature).and_call_original
        allow(buzz_feature_registry).to receive(:define_list_item_feature).and_call_original
        layer.define_list_item_feature(:baz, :baz_0) do
          fizz {}
          buzz {}
          shared_context { contexts << self }
        end
        expect(fizz_feature_registry).to have_received(:define_list_item_feature).with(:baz, :baz_0, equal(contexts.last))
        expect(buzz_feature_registry).to have_received(:define_list_item_feature).with(:baz, :baz_0, equal(contexts.last))
      end

      specify '異なるフィーチャー間では、共有コンテキストは独立している' do
        contexts = []

        layer.define_simple_feature([:foo_0, :foo_1]) do
          shared_context { contexts << self }
        end
        layer.define_list_feature([:bar_0, :bar_1]) do
          shared_context { contexts << self }
        end
        layer.define_list_feature(:baz) do
          fizz {}
          buzz {}
        end
        layer.define_list_item_feature(:baz, [:baz_0, :baz_1]) do
          shared_context { contexts << self }
        end

        expect(contexts.size).to eq contexts.map(&:object_id).uniq.size
      end

      specify '同一フィーチャー間では、共有コンテキストは共有される' do
        contexts = []

        layer.define_simple_feature(:foo) do
          shared_context { contexts << self }
        end
        layer.define_simple_feature(:foo) do
          shared_context { contexts << self }
        end
        expect(contexts[0]).to equal contexts[1]

        layer.define_list_feature(:bar) do
          shared_context { contexts << self }
        end
        layer.define_list_feature(:bar) do
          shared_context { contexts << self }
        end
        expect(contexts[2]).to equal contexts[3]

        layer.define_list_feature(:baz) {}
        layer.define_list_item_feature(:baz, :baz_0) do
          shared_context { contexts << self }
        end
        layer.define_list_item_feature(:baz, :baz_0) do
          shared_context { contexts << self }
        end
        expect(contexts[4]).to equal contexts[5]
      end
    end
  end

  describe 'フィーチャーの有効化' do
    before do
      layer.define_simple_feature([:foo_0, :foo_1, :foo_2]) do
        fizz {}
        buzz {}
      end
      layer.define_list_feature([:bar_0, :bar_1, :bar_2]) do
        fizz {}
        buzz {}
      end
      layer.define_list_item_feature(:bar_0, [:bar_0_0, :bar_0_1, :bar_0_2, :bar_0_3]) do
        fizz {}
        buzz {}
      end
    end

    specify '#enableで指定したフィーチャーを有効にする' do
      expect(fizz_feature_registry).to receive(:enable).with(:foo_0, nil)
      expect(buzz_feature_registry).to receive(:enable).with(:foo_0, nil)
      layer.enable(:foo_0)

      expect(fizz_feature_registry).to receive(:enable).with([:foo_1, :bar_0], nil)
      expect(buzz_feature_registry).to receive(:enable).with([:foo_1, :bar_0], nil)
      layer.enable([:foo_1, :bar_0])

      expect(fizz_feature_registry).to receive(:enable).with(:bar_0, :bar_0_0)
      expect(buzz_feature_registry).to receive(:enable).with(:bar_0, :bar_0_0)
      layer.enable(:bar_0, :bar_0_0)

      expect(fizz_feature_registry).to receive(:enable).with(:bar_0, [:bar_0_1, :bar_0_2])
      expect(buzz_feature_registry).to receive(:enable).with(:bar_0, [:bar_0_1, :bar_0_2])
      layer.enable(:bar_0, [:bar_0_1, :bar_0_2])
    end
  end

  describe 'フィーチャーの無効化' do
    before do
      layer.define_simple_feature([:foo_0, :foo_1, :foo_2]) do
        fizz {}
        buzz {}
      end
      layer.define_list_feature([:bar_0, :bar_1, :bar_2]) do
        fizz {}
        buzz {}
      end
      layer.define_list_item_feature(:bar_0, [:bar_0_0, :bar_0_1, :bar_0_2, :bar_0_3]) do
        fizz {}
        buzz {}
      end
    end

    context '#deleteを無引数で呼び出した場合' do
      it 'フィーチャーを全て無効化する' do
        expect(fizz_feature_registry).to receive(:disable).with(no_args)
        expect(buzz_feature_registry).to receive(:disable).with(no_args)
        layer.disable
      end
    end

    context '引数でフィーチャー名が指定された場合' do
      it '指定されたフィーチャーを無効化する' do
        expect(fizz_feature_registry).to receive(:disable).with(:foo_0)
        expect(buzz_feature_registry).to receive(:disable).with(:foo_0)
        layer.disable(:foo_0)

        expect(fizz_feature_registry).to receive(:disable).with(match([:foo_1, :bar_1]))
        expect(buzz_feature_registry).to receive(:disable).with(match([:foo_1, :bar_1]))
        layer.disable([:foo_1, :bar_1])

        expect(fizz_feature_registry).to receive(:disable).with(:bar_0, :bar_0_0)
        expect(buzz_feature_registry).to receive(:disable).with(:bar_0, :bar_0_0)
        layer.disable(:bar_0, :bar_0_0)

        expect(fizz_feature_registry).to receive(:disable).with(:bar_0, match([:bar_0_1, :bar_0_2]))
        expect(buzz_feature_registry).to receive(:disable).with(:bar_0, match([:bar_0_1, :bar_0_2]))
        layer.disable(:bar_0, [:bar_0_1, :bar_0_2])
      end
    end
  end

  describe '定義済みフィーチャーの削除' do
    before do
      layer.define_simple_feature([:foo_0, :foo_1, :foo_2]) do
        fizz {}
        buzz {}
      end
      layer.define_list_feature([:bar_0, :bar_1, :bar_2]) do
        fizz {}
        buzz {}
      end
      layer.define_list_item_feature(:bar_0, [:bar_0_0, :bar_0_1, :bar_0_2, :bar_0_3]) do
        fizz {}
        buzz {}
      end
    end

    context '#deleteを無引数で呼び出した場合' do
      it '定義済みフィーチャーを全て削除する' do
        expect(fizz_feature_registry).to receive(:delete).with(no_args)
        expect(buzz_feature_registry).to receive(:delete).with(no_args)
        layer.delete
      end
    end

    context '引数でフィーチャー名が指定された場合' do
      it '指定されたフィーチャーを削除する' do
        expect(fizz_feature_registry).to receive(:delete).with(:foo_0)
        expect(buzz_feature_registry).to receive(:delete).with(:foo_0)
        layer.delete(:foo_0)

        expect(fizz_feature_registry).to receive(:delete).with(match([:foo_1, :bar_1]))
        expect(buzz_feature_registry).to receive(:delete).with(match([:foo_1, :bar_1]))
        layer.delete([:foo_1, :bar_1])

        expect(fizz_feature_registry).to receive(:delete).with(:bar_0, :bar_0_0)
        expect(buzz_feature_registry).to receive(:delete).with(:bar_0, :bar_0_0)
        layer.delete(:bar_0, :bar_0_0)

        expect(fizz_feature_registry).to receive(:delete).with(:bar_0, match([:bar_0_1, :bar_0_2]))
        expect(buzz_feature_registry).to receive(:delete).with(:bar_0, match([:bar_0_1, :bar_0_2]))
        layer.delete(:bar_0, [:bar_0_1, :bar_0_2])
      end
    end
  end
end
