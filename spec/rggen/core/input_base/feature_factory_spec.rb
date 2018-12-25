require 'spec_helper'

module RgGen::Core::InputBase
  describe FeatureFactory do
    let(:feature_name) { :feature_name }

    let(:active_feature) { Class.new(Feature) { build {} } }
    let(:passive_feature) { Class.new(Feature) }

    describe "#create" do
      let(:component) { RgGen::Core::Base::Component.new }

      let(:active_factory) do
        FeatureFactory.new(feature_name) { |f| f.target_feature active_feature }
      end

      let(:passive_factory) do
        FeatureFactory.new(feature_name) { |f| f.target_feature passive_feature }
      end

      let(:input_value) { InputValue.new(:foo, position) }

      let(:position) { Struct.new(:x, :y).new(0, 1) }

      it "#create_featureを呼んで、フィーチャーを生成する" do
        expect(active_factory).to receive(:create_feature).and_call_original
        expect(passive_factory).to receive(:create_feature).and_call_original
        active_factory.create(component, :other_arg, input_value)
        passive_factory.create(component)
      end

      describe "フィーチャーの組み立て" do
        it "末尾の引数を用いて、フィーチャーの組み立てを行う" do
          expect_any_instance_of(active_feature).to receive(:build).with(equal(input_value))
          active_factory.create(component, :other_arg, input_value)
        end

        context "入力データが空データの場合" do
          it "フィーチャーの組み立てを行わない" do
            expect_any_instance_of(active_feature).not_to receive(:build)
            active_factory.create(component, :other_arg, NilValue)
          end
        end

        context "対象フィーチャーが受動フィーチャーの場合" do
          it "フィーチャーの組み立てを行わない" do
            expect_any_instance_of(passive_feature).not_to receive(:build)
            passive_factory.create(component)
          end
        end
      end

      describe "入力値の変換" do
        let(:feature_class) do
          Class.new(Feature) do
            field :value
            build { |value| @value = value }
          end
        end

        let(:factory_class) do
          Class.new(FeatureFactory) do
            convert_value { |value| upcase(value) }
            def upcase(value); value.upcase end
          end
        end

        let(:active_factory) do
          factory_class.new(feature_name) { |f| f.target_feature feature_class }
        end

        let(:passive_factory) do
          factory_class.new(feature_name) { |f| f.target_feature passive_feature }
        end

        let(:feature) { active_factory.create(component, input_value) }

        it ".convert_valueで登録されたブロックを実行し、入力値の変換を行う" do
          expect(active_factory).to receive(:upcase).and_call_original
          expect(feature.value).to eq :FOO
        end

        specify "変換後も位置情報は維持される" do
          expect(feature.send(:position)).to eq position
        end

        specify "引数として与えられた入力値は変化しない" do
          active_factory.create(component, input_value)
          expect(input_value.value).to eq :foo
        end

        it "入力が空データの場合は、入力値の変換を行わない" do
          expect(active_factory).not_to receive(:upcase)
          active_factory.create(component, NilValue)
        end

        it "対象フィーチャーが受動フィーチャーの場合は、入力値の変換を行わない" do
          expect(passive_factory).not_to receive(:upcase)
          passive_factory.create(component, input_value)
        end
      end
    end

    describe "#active_feature_factory?/#passive_feature_factory?" do
      let(:simple_active_feature_factory) do
        FeatureFactory.new(feature_name) { |f| f.target_feature active_feature }
      end

      let(:simple_passive_feature_factory) do
        FeatureFactory.new(feature_name) { |f| f.target_feature passive_feature }
      end

      let(:multiple_features_factory) do
        FeatureFactory.new(feature_name) do |f|
          f.target_feature passive_feature
          f.target_features foo: active_feature, bar: passive_feature
        end
      end

      specify "能動フィーチャーを#target_featureに持つファクトリは能動フィーチャーファクトリ" do
        expect(simple_active_feature_factory).to be_active_feature_factory
        expect(simple_active_feature_factory).not_to be_passive_feature_factory
      end

      specify "受動フィーチャーを#target_featureに持つファクトリは受動フィーチャーファクトリ" do
        expect(simple_passive_feature_factory).not_to be_active_feature_factory
        expect(simple_passive_feature_factory).to be_passive_feature_factory
      end

      specify "#target_featuresを持つファクトリは能動フィーチャーファクトリ" do
        expect(multiple_features_factory).to be_active_feature_factory
        expect(multiple_features_factory).not_to be_passive_feature_factory
      end
    end
  end
end
