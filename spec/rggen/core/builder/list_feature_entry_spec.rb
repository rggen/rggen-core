# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::Builder
  describe ListFeatureEntry do
    let(:feature_name) { :feature }

    let(:feature_base) { RgGen::Core::InputBase::Feature }

    let(:factory_base) do
      Class.new(RgGen::Core::InputBase::FeatureFactory) do
        def create(*args)
          create_feature(*args)
        end
      end
    end

    let(:component) { RgGen::Core::InputBase::Component.new(nil) }

    let(:feature_registry) { double('feature_registry') }

    let(:default_factory_body) do
      proc { def select_feature(key); @target_features[key]; end }
    end

    def create_entry(context = nil, &body)
      entry = ListFeatureEntry.new(feature_registry, feature_name)
      entry.setup(feature_base, factory_base, context, body)
      entry
    end

    describe "ファクトリの定義" do
      specify "#build_factoryでエントリー生成時に指定したファクトリを生成する" do
        entry = create_entry
        factory = entry.build_factory([])
        expect(factory).to be_kind_of factory_base
        expect(factory).not_to be_instance_of factory_base
      end

      specify "#define_factory/#factoryでファクトリの定義を行える" do
        entry = create_entry do
          define_factory { def foo; 'foo!'; end }
          factory { def bar; 'bar!'; end }
        end

        factory = entry.build_factory([])
        expect(factory.foo).to eq 'foo!'
        expect(factory.bar).to eq 'bar!'
      end
    end

    describe "フィーチャーの定義" do
      specify "生成したファクトリで、#define_feature/#featureで定義したフィーチャーを生成できる" do
        entry = create_entry do
          define_factory(&default_factory_body)
          define_feature(:foo) { def fizz; 'foo fizz!'; end }
          feature(:foo) { def buzz; 'foo buzz!'; end }
          define_feature(:bar) { def fizz; 'bar fizz!'; end }
          feature(:bar) { def buzz; 'bar buzz!'; end }
          define_feature(:baz) { def fizz; 'baz fizz!'; end }
          feature(:baz) { def buzz; 'baz buzz!'; end }
        end

        factory = entry.build_factory([:foo, :bar, :baz])
        [:foo, :bar, :baz].each do |key|
          feature = factory.create(component, key)
          expect(feature.fizz).to eq "#{key} fizz!"
          expect(feature.buzz).to eq "#{key} buzz!"
        end
      end

      specify "ファクトリ生成時に指定したフィーチャーが生成できる" do
        exception = Class.new(StandardError)

        entry = create_entry do
          define_factory do
            define_method(:select_feature) { |key| @target_features[key] || (raise exception) }
          end
          define_feature(:foo)
          define_feature(:bar)
          define_feature(:baz)
        end

        factory = entry.build_factory([:foo, :bar])
        expect {
          factory.create(component, :foo)
          factory.create(component, :bar)
        }.not_to raise_error
        expect {
          factory.create(component, :baz)
        }.to raise_error exception
      end

      describe "既定フィーチャーの定義" do
        context "#define_featureで定義したフィーチャーから対象フィーチャーを選択できなかった場合" do
          specify "#define_deault_feature/default_featureで定義した既定フィーチャーが生成される" do
            entry = create_entry do
              define_factory(&default_factory_body)
              define_default_feature { def fizz; 'fizz!'; end}
              default_feature { def buzz; 'buzz!'; end}
            end

            feature = entry.build_factory([]).create(component, :foo)
            expect(feature.fizz).to eq 'fizz!'
            expect(feature.buzz).to eq 'buzz!'
          end
        end
      end

      describe "親フィーチャーの定義" do
        specify "#define_base_feature/base_featureで各フィーチャーの親フィーチャーを定義できる" do
          entry = create_entry do
            define_factory(&default_factory_body)
            define_base_feature { def fizz; 'fizz!'; end }
            base_feature { def buzz; 'buzz!'; end }
            define_feature(:foo) {}
            define_feature(:bar) {}
            define_default_feature {}
          end

          factory = entry.build_factory([:foo, :bar])
          [:foo, :bar, :baz].map do |feature_name|
            entry = factory.create(component, feature_name)
            expect(entry.fizz).to eq 'fizz!'
            expect(entry.buzz).to eq 'buzz!'
          end
        end
      end

      specify "エントリ生成時に指定した名称が、生成されるフィーチャーの名称になる" do
        entry = create_entry do
          define_factory(&default_factory_body)
          define_feature(:foo)
          define_default_feature
        end

        factory = entry.build_factory([:foo])
        [:foo, :bar].each do |key|
          feature = factory.create(component, key)
          expect(feature.feature_name).to eq feature_name
        end
      end
    end

    describe "共通コンテキスト" do
      context "エントリー生成時に共通オブジェクトが与えられた場合" do
        specify "エントリー/親フィーチャー/ファクトリに共通コンテキストが設定される" do
          shared_context = Object.new

          entry = create_entry(shared_context) do
            define_factory(&default_factory_body)
            define_feature(:foo)
            define_default_feature
          end

          factory = entry.build_factory([:foo])
          features = [factory.create(component, :foo), factory.create(component, :bar)]

          expect(entry.send(:shared_context)).to be shared_context
          expect(factory.send(:shared_context)).to be shared_context
          expect(features[0].send(:shared_context)).to be shared_context
          expect(features[1].send(:shared_context)).to be shared_context
        end
      end

      context "フィーチャーの定義時に与えられた場合" do
        specify "定義したフィーチャーに共通コンテキストが設定される" do
          shared_contexts = { foo: Object.new, bar: Object.new }

          entry = create_entry do
            define_factory(&default_factory_body)
            define_feature(:foo, shared_contexts[:foo])
            define_feature(:bar, shared_contexts[:bar])
          end

          factory = entry.build_factory([:foo, :bar])
          features = {}
          features[:foo] = factory.create(component, :foo)
          features[:bar] = factory.create(component, :bar)

          features.each do |feature_name, feature|
            expect(feature.send(:shared_context)).to be shared_contexts[feature_name]
          end
        end

        specify "共通コンテキストは複数回設定できない" do
          shared_context = Object.new

          entry = create_entry(shared_context)
          expect {
            entry.define_feature(:foo, shared_context)
          }.to raise_error RgGen::Core::BuilderError, 'shared context has already been set'

          entry = create_entry
          entry.define_feature(:foo, shared_context)
          expect {
            entry.define_feature(:foo, shared_context)
          }.to raise_error RgGen::Core::BuilderError, 'shared context has already been set'
        end
      end
    end

    describe "#defined_feature?" do
      let(:entry) do
        create_entry do
          define_feature(:foo)
          define_feature(:bar)
        end
      end

      it "定義済みのフィーチャーかどうかを返す" do
        expect(entry.defined_feature?(:foo)).to be true
        expect(entry.defined_feature?(:bar)).to be true
        expect(entry.defined_feature?(:baz)).to be false
      end
    end
  end
end
