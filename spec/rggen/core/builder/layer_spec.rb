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

  describe '#component_defined?' do
    it '指定したコンポーネントが定義済みかどうかを返す' do
      expect(layer.component_defined?(:fizz)).to eq true
      expect(layer.component_defined?(:buzz)).to eq true
      expect(layer.component_defined?(:foo)).to eq false
      expect(layer.component_defined?(:bar)).to eq false
    end
  end

  def create_proc_monitor(call_count)
    Object.new.tap do |monitor|
      def monitor.to_proc
        m = self
        proc { m.call }
      end
      expect(monitor).to receive(:call).exactly(call_count).times
    end
  end

  describe 'フィーチャーの定義' do
    specify '#add_feature_registry呼び出し時に指定した登録名でフィーチャーを定義できる' do
      fizz_checker = create_proc_monitor(2)
      buzz_checker = create_proc_monitor(2)
      expect(fizz_feature_registry).to receive(:define_feature).with(:foo_0, nil, anything).and_call_original
      expect(buzz_feature_registry).to receive(:define_feature).with(:foo_0, nil, anything).and_call_original
      layer.define_feature(:foo_0) do
        fizz(&fizz_checker)
        buzz(&buzz_checker)
        component(:fizz, &fizz_checker)
        component(:buzz, &buzz_checker)
      end

      fizz_checker = create_proc_monitor(4)
      buzz_checker = create_proc_monitor(4)
      expect(fizz_feature_registry).to receive(:define_feature).with(:foo_1, nil, anything).and_call_original
      expect(buzz_feature_registry).to receive(:define_feature).with(:foo_1, nil, anything).and_call_original
      expect(fizz_feature_registry).to receive(:define_feature).with(:foo_2, nil, anything).and_call_original
      expect(buzz_feature_registry).to receive(:define_feature).with(:foo_2, nil, anything).and_call_original
      layer.define_feature([:foo_1, :foo_2]) do
        fizz(&fizz_checker)
        buzz(&buzz_checker)
        component(:fizz, &fizz_checker)
        component(:buzz, &buzz_checker)
      end

      fizz_checker = create_proc_monitor(2)
      buzz_checker = create_proc_monitor(2)
      expect(fizz_feature_registry).to receive(:define_simple_feature).with(:bar_0, nil, anything).and_call_original
      expect(buzz_feature_registry).to receive(:define_simple_feature).with(:bar_0, nil, anything).and_call_original
      layer.define_simple_feature(:bar_0) do
        fizz(&fizz_checker)
        buzz(&buzz_checker)
        component(:fizz, &fizz_checker)
        component(:buzz, &buzz_checker)
      end

      fizz_checker = create_proc_monitor(4)
      buzz_checker = create_proc_monitor(4)
      expect(fizz_feature_registry).to receive(:define_simple_feature).with(:bar_1, nil, anything).and_call_original
      expect(buzz_feature_registry).to receive(:define_simple_feature).with(:bar_1, nil, anything).and_call_original
      expect(fizz_feature_registry).to receive(:define_simple_feature).with(:bar_2, nil, anything).and_call_original
      expect(buzz_feature_registry).to receive(:define_simple_feature).with(:bar_2, nil, anything).and_call_original
      layer.define_simple_feature([:bar_1, :bar_2]) do
        fizz(&fizz_checker)
        buzz(&buzz_checker)
        component(:fizz, &fizz_checker)
        component(:buzz, &buzz_checker)
      end

      fizz_checker = create_proc_monitor(2)
      buzz_checker = create_proc_monitor(2)
      expect(fizz_feature_registry).to receive(:define_list_feature).with(:baz_0, nil, anything).and_call_original
      expect(buzz_feature_registry).to receive(:define_list_feature).with(:baz_0, nil, anything).and_call_original
      layer.define_list_feature(:baz_0) do
        fizz(&fizz_checker)
        buzz(&buzz_checker)
        component(:fizz, &fizz_checker)
        component(:buzz, &buzz_checker)
      end

      fizz_checker = create_proc_monitor(2)
      buzz_checker = create_proc_monitor(2)
      expect(fizz_feature_registry).to receive(:define_list_item_feature).with(:baz_0, :baz_0_0, nil, anything).and_call_original
      expect(buzz_feature_registry).to receive(:define_list_item_feature).with(:baz_0, :baz_0_0, nil, anything).and_call_original
      layer.define_list_item_feature(:baz_0, :baz_0_0) do
        fizz(&fizz_checker)
        buzz(&buzz_checker)
        component(:fizz, &fizz_checker)
        component(:buzz, &buzz_checker)
      end

      fizz_checker = create_proc_monitor(4)
      buzz_checker = create_proc_monitor(4)
      expect(fizz_feature_registry).to receive(:define_list_item_feature).with(:baz_0, :baz_0_1, nil, anything).and_call_original
      expect(buzz_feature_registry).to receive(:define_list_item_feature).with(:baz_0, :baz_0_1, nil, anything).and_call_original
      expect(fizz_feature_registry).to receive(:define_list_item_feature).with(:baz_0, :baz_0_2, nil, anything).and_call_original
      expect(buzz_feature_registry).to receive(:define_list_item_feature).with(:baz_0, :baz_0_2, nil, anything).and_call_original
      layer.define_list_item_feature(:baz_0, [:baz_0_1, :baz_0_2]) do
        fizz(&fizz_checker)
        buzz(&buzz_checker)
        component(:fizz, &fizz_checker)
        component(:buzz, &buzz_checker)
      end

      fizz_checker = create_proc_monitor(4)
      buzz_checker = create_proc_monitor(4)
      expect(fizz_feature_registry).to receive(:define_list_feature).with(:qux_0, nil, anything).and_call_original
      expect(buzz_feature_registry).to receive(:define_list_feature).with(:qux_0, nil, anything).and_call_original
      expect(fizz_feature_registry).to receive(:define_list_feature).with(:qux_1, nil, anything).and_call_original
      expect(buzz_feature_registry).to receive(:define_list_feature).with(:qux_1, nil, anything).and_call_original
      layer.define_list_feature([:qux_0, :qux_1]) do
        fizz(&fizz_checker)
        buzz(&buzz_checker)
        component(:fizz, &fizz_checker)
        component(:buzz, &buzz_checker)
      end
    end

    context '共有コンテキストが有効な場合' do
      specify 'フィーチャー定義時に共有コンテキストが渡される' do
        contexts = []

        allow(fizz_feature_registry).to receive(:define_feature).and_call_original
        allow(buzz_feature_registry).to receive(:define_feature).and_call_original
        layer.define_feature(:foo) do
          fizz {}; buzz {};
          contexts << shared_context {}
        end
        expect(fizz_feature_registry).to have_received(:define_feature).with(:foo, equal(contexts.last), anything)
        expect(buzz_feature_registry).to have_received(:define_feature).with(:foo, equal(contexts.last), anything)

        allow(fizz_feature_registry).to receive(:define_simple_feature).and_call_original
        allow(buzz_feature_registry).to receive(:define_simple_feature).and_call_original
        layer.define_simple_feature(:bar) do
          fizz {}; buzz {}
          contexts << shared_context {}
        end
        expect(fizz_feature_registry).to have_received(:define_simple_feature).with(:bar, equal(contexts.last), anything)
        expect(buzz_feature_registry).to have_received(:define_simple_feature).with(:bar, equal(contexts.last), anything)

        allow(fizz_feature_registry).to receive(:define_list_feature).and_call_original
        allow(buzz_feature_registry).to receive(:define_list_feature).and_call_original
        layer.define_list_feature(:baz) do
          fizz {}; buzz {}
          contexts << shared_context {}
        end
        expect(fizz_feature_registry).to have_received(:define_list_feature).with(:baz, equal(contexts.last), anything)
        expect(buzz_feature_registry).to have_received(:define_list_feature).with(:baz, equal(contexts.last), anything)

        layer.define_list_feature(:qux) do
          fizz {}; buzz {}
        end
        allow(fizz_feature_registry).to receive(:define_list_item_feature).and_call_original
        allow(buzz_feature_registry).to receive(:define_list_item_feature).and_call_original
        layer.define_list_item_feature(:qux, :qux_0) do
          fizz {}; buzz {}
          contexts << shared_context {}
        end
        expect(fizz_feature_registry).to have_received(:define_list_item_feature).with(:qux, :qux_0, equal(contexts.last), anything)
        expect(buzz_feature_registry).to have_received(:define_list_item_feature).with(:qux, :qux_0, equal(contexts.last), anything)
      end

      specify '異なるフィーチャー間では、共有コンテキストは独立している' do
        contexts = []

        layer.define_feature([:foo_0, :foo_1]) do
          shared_context { contexts << self }
        end
        layer.define_simple_feature([:bar_0, :bar_1]) do
          shared_context { contexts << self }
        end
        layer.define_list_feature([:baz_0, :baz_1]) do
          shared_context { contexts << self }
        end
        layer.define_list_feature(:qux) do
          fizz {}; buzz {}
        end
        layer.define_list_item_feature(:qux, [:qux_0, :qux_1]) do
          shared_context { contexts << self }
        end

        expect(contexts.size).to eq contexts.map(&:object_id).uniq.size
      end

      specify '同一フィーチャー間では、共有コンテキストは共有される' do
        contexts = []

        layer.define_feature(:foo) do
          shared_context { contexts << self }
        end
        layer.define_feature(:foo) do
          shared_context { contexts << self }
        end
        expect(contexts[0]).to equal contexts[1]

        layer.define_simple_feature(:bar) do
          shared_context { contexts << self }
        end
        layer.define_simple_feature(:bar) do
          shared_context { contexts << self }
        end
        expect(contexts[2]).to equal contexts[3]

        layer.define_list_feature(:baz) do
          shared_context { contexts << self }
        end
        layer.define_list_feature(:baz) do
          shared_context { contexts << self }
        end
        expect(contexts[4]).to equal contexts[5]

        layer.define_list_feature(:qux) {}
        layer.define_list_item_feature(:qux, :qux_0) do
          shared_context { contexts << self }
        end
        layer.define_list_item_feature(:qux, :qux_0) do
          shared_context { contexts << self }
        end
        expect(contexts[6]).to equal contexts[7]
      end
    end

    context '未登録のコンポーネントが指定された場合' do
      it 'BuilderErrorを起こす' do
        expect { layer.define_feature(:foo) { component(:foo) } }
          .to raise_rggen_error RgGen::Core::BuilderError, "unknown component: foo"
      end
    end
  end

  describe 'フィーチャーの変更' do
    specify '#add_feature_registry呼び出し時に指定した登録名でフィーチャーを変更できる' do
      layer.define_feature(:foo_0) { fizz {}; buzz {} }
      fizz_checker = create_proc_monitor(2)
      buzz_checker = create_proc_monitor(2)
      expect(fizz_feature_registry).to receive(:modify_feature).with(:foo_0, anything).and_call_original
      expect(buzz_feature_registry).to receive(:modify_feature).with(:foo_0, anything).and_call_original
      layer.modify_feature(:foo_0) do
        fizz(&fizz_checker)
        buzz(&buzz_checker)
        component(:fizz, &fizz_checker)
        component(:buzz, &buzz_checker)
      end

      layer.define_feature([:foo_1, :foo_2]) { fizz {}; buzz {} }
      fizz_checker = create_proc_monitor(4)
      buzz_checker = create_proc_monitor(4)
      expect(fizz_feature_registry).to receive(:modify_feature).with(:foo_1, anything).and_call_original
      expect(buzz_feature_registry).to receive(:modify_feature).with(:foo_1, anything).and_call_original
      expect(fizz_feature_registry).to receive(:modify_feature).with(:foo_2, anything).and_call_original
      expect(buzz_feature_registry).to receive(:modify_feature).with(:foo_2, anything).and_call_original
      layer.modify_feature([:foo_1, :foo_2]) do
        fizz(&fizz_checker)
        buzz(&buzz_checker)
        component(:fizz, &fizz_checker)
        component(:buzz, &buzz_checker)
      end

      layer.define_simple_feature(:bar_0) { fizz {}; buzz {} }
      fizz_checker = create_proc_monitor(2)
      buzz_checker = create_proc_monitor(2)
      expect(fizz_feature_registry).to receive(:modify_simple_feature).with(:bar_0, anything).and_call_original
      expect(buzz_feature_registry).to receive(:modify_simple_feature).with(:bar_0, anything).and_call_original
      layer.modify_simple_feature(:bar_0) do
        fizz(&fizz_checker)
        buzz(&buzz_checker)
        component(:fizz, &fizz_checker)
        component(:buzz, &buzz_checker)
      end

      layer.define_simple_feature([:bar_1, :bar_2]) { fizz {}; buzz {} }
      fizz_checker = create_proc_monitor(4)
      buzz_checker = create_proc_monitor(4)
      expect(fizz_feature_registry).to receive(:modify_simple_feature).with(:bar_1, anything).and_call_original
      expect(buzz_feature_registry).to receive(:modify_simple_feature).with(:bar_1, anything).and_call_original
      expect(fizz_feature_registry).to receive(:modify_simple_feature).with(:bar_2, anything).and_call_original
      expect(buzz_feature_registry).to receive(:modify_simple_feature).with(:bar_2, anything).and_call_original
      layer.modify_simple_feature([:bar_1, :bar_2]) do
        fizz(&fizz_checker)
        buzz(&buzz_checker)
        component(:fizz, &fizz_checker)
        component(:buzz, &buzz_checker)
      end

      layer.define_list_feature(:baz_0) { fizz {}; buzz {} }
      fizz_checker = create_proc_monitor(2)
      buzz_checker = create_proc_monitor(2)
      expect(fizz_feature_registry).to receive(:modify_list_feature).with(:baz_0, anything).and_call_original
      expect(buzz_feature_registry).to receive(:modify_list_feature).with(:baz_0, anything).and_call_original
      layer.modify_list_feature(:baz_0) do
        fizz(&fizz_checker)
        buzz(&buzz_checker)
        component(:fizz, &fizz_checker)
        component(:buzz, &buzz_checker)
      end

      layer.define_list_feature([:baz_1, :baz_2]) { fizz {}; buzz {} }
      fizz_checker = create_proc_monitor(4)
      buzz_checker = create_proc_monitor(4)
      expect(fizz_feature_registry).to receive(:modify_list_feature).with(:baz_1, anything).and_call_original
      expect(buzz_feature_registry).to receive(:modify_list_feature).with(:baz_1, anything).and_call_original
      expect(fizz_feature_registry).to receive(:modify_list_feature).with(:baz_2, anything).and_call_original
      expect(buzz_feature_registry).to receive(:modify_list_feature).with(:baz_2, anything).and_call_original
      layer.modify_list_feature([:baz_1, :baz_2]) do
        fizz(&fizz_checker)
        buzz(&buzz_checker)
        component(:fizz, &fizz_checker)
        component(:buzz, &buzz_checker)
      end

      layer.define_list_item_feature(:baz_0, :baz_0_0) { fizz {}; buzz {} }
      fizz_checker = create_proc_monitor(2)
      buzz_checker = create_proc_monitor(2)
      expect(fizz_feature_registry).to receive(:modify_list_item_feature).with(:baz_0, :baz_0_0, anything).and_call_original
      expect(buzz_feature_registry).to receive(:modify_list_item_feature).with(:baz_0, :baz_0_0, anything).and_call_original
      layer.modify_list_item_feature(:baz_0, :baz_0_0) do
        fizz(&fizz_checker)
        buzz(&buzz_checker)
        component(:fizz, &fizz_checker)
        component(:buzz, &buzz_checker)
      end

      layer.define_list_item_feature(:baz_0, [:baz_0_1, :baz_0_2]) { fizz {}; buzz {} }
      fizz_checker = create_proc_monitor(4)
      buzz_checker = create_proc_monitor(4)
      expect(fizz_feature_registry).to receive(:modify_list_item_feature).with(:baz_0, :baz_0_1, anything).and_call_original
      expect(buzz_feature_registry).to receive(:modify_list_item_feature).with(:baz_0, :baz_0_1, anything).and_call_original
      expect(fizz_feature_registry).to receive(:modify_list_item_feature).with(:baz_0, :baz_0_2, anything).and_call_original
      expect(buzz_feature_registry).to receive(:modify_list_item_feature).with(:baz_0, :baz_0_2, anything).and_call_original
      layer.modify_list_item_feature(:baz_0, [:baz_0_1, :baz_0_2]) do
        fizz(&fizz_checker)
        buzz(&buzz_checker)
        component(:fizz, &fizz_checker)
        component(:buzz, &buzz_checker)
      end
    end

    context '未登録のコンポーネントが指定された場合' do
      it 'BuilderErrorを起こす' do
        expect { layer.modify_feature(:foo) { component(:foo) } }
          .to raise_rggen_error RgGen::Core::BuilderError, "unknown component: foo"
      end
    end
  end

  describe 'フィーチャーの有効化' do
    before do
      layer.define_feature([:foo_0, :foo_1, :foo_2]) do
        fizz {}; buzz {}
      end
      layer.define_simple_feature([:bar_0, :bar_1, :bar_2]) do
        fizz {}; buzz {}
      end
      layer.define_list_feature([:baz_0, :baz_1, :baz_2]) do
        fizz {}; buzz {}
      end
      layer.define_list_item_feature(:baz_0, [:baz_0_0, :baz_0_1, :baz_0_2, :baz_0_3]) do
        fizz {}; buzz {}
      end
    end

    specify '#enableで指定したフィーチャーを有効にする' do
      expect(fizz_feature_registry).to receive(:enable).with(:foo_0).and_call_original
      expect(buzz_feature_registry).to receive(:enable).with(:foo_0).and_call_original
      layer.enable(:foo_0)

      expect(fizz_feature_registry).to receive(:enable).with(:bar_0).and_call_original
      expect(buzz_feature_registry).to receive(:enable).with(:bar_0).and_call_original
      layer.enable(:bar_0)

      expect(fizz_feature_registry).to receive(:enable).with([:foo_2, :bar_1, :baz_0]).and_call_original
      expect(buzz_feature_registry).to receive(:enable).with([:foo_2, :bar_1, :baz_0]).and_call_original
      layer.enable([:foo_2, :bar_1, :baz_0])

      expect(fizz_feature_registry).to receive(:enable).with(:baz_0, :baz_0_0).and_call_original
      expect(buzz_feature_registry).to receive(:enable).with(:baz_0, :baz_0_0).and_call_original
      layer.enable(:baz_0, :baz_0_0)

      expect(fizz_feature_registry).to receive(:enable).with(:baz_0, [:baz_0_1, :baz_0_2]).and_call_original
      expect(buzz_feature_registry).to receive(:enable).with(:baz_0, [:baz_0_1, :baz_0_2]).and_call_original
      layer.enable(:baz_0, [:baz_0_1, :baz_0_2])
    end

    specify '#enable_allで定義した全フィーチャーを有効化する' do
      expect(fizz_feature_registry).to receive(:enable_all).and_call_original
      expect(buzz_feature_registry).to receive(:enable_all).and_call_original
      layer.enable_all
    end
  end

  describe '定義済みフィーチャーの削除' do
    before do
      layer.define_feature([:foo_0, :foo_1, :foo_2]) do
        fizz {}; buzz {}
      end
      layer.define_simple_feature([:bar_0, :bar_1, :bar_2]) do
        fizz {}; buzz {}
      end
      layer.define_list_feature([:baz_0, :baz_1, :baz_2]) do
        fizz {}; buzz {}
      end
      layer.define_list_item_feature(:baz_0, [:baz_0_0, :baz_0_1, :baz_0_2, :baz_0_3]) do
        fizz {}; buzz {}
      end
    end

    context '#delete_allを呼び出した場合' do
      it '定義済みフィーチャーを全て削除する' do
        expect(fizz_feature_registry).to receive(:delete_all)
        expect(buzz_feature_registry).to receive(:delete_all)
        layer.delete_all
      end
    end

    context '引数でフィーチャー名が指定された場合' do
      it '指定されたフィーチャーを削除する' do
        expect(fizz_feature_registry).to receive(:delete).with(:foo_0)
        expect(buzz_feature_registry).to receive(:delete).with(:foo_0)
        layer.delete(:foo_0)

        expect(fizz_feature_registry).to receive(:delete).with(match([:foo_1, :bar_1, :baz_1]))
        expect(buzz_feature_registry).to receive(:delete).with(match([:foo_1, :bar_1, :baz_1]))
        layer.delete([:foo_1, :bar_1, :baz_1])

        expect(fizz_feature_registry).to receive(:delete).with(:baz_0, :baz_0_0)
        expect(buzz_feature_registry).to receive(:delete).with(:baz_0, :baz_0_0)
        layer.delete(:baz_0, :baz_0_0)

        expect(fizz_feature_registry).to receive(:delete).with(:baz_0, match([:baz_0_1, :baz_0_2]))
        expect(buzz_feature_registry).to receive(:delete).with(:baz_0, match([:baz_0_1, :baz_0_2]))
        layer.delete(:baz_0, [:baz_0_1, :baz_0_2])
      end
    end
  end
end
