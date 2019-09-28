# frozen_string_literal: true

require  'spec_helper'

module RgGen::Core::Base
  describe Feature do
    let(:component) { Component.new('component') }

    let(:feature_class) { Class.new(Feature) }

    let(:feature_name) { 'foo' }

    let(:sub_feature_name) { ['', nil].sample }

    let(:feature) { feature_class.new(feature_name, sub_feature_name, component) }

    describe '#component' do
      it 'オーナーコンポーネントを返す' do
        expect(feature.component).to eql component
      end
    end

    describe '#feature_name' do
      context '副フィーチャー名が設定されていて' do
        let(:sub_feature_name) { 'bar' }

        context 'verboseが未指定の場合' do
          it 'フィーチャー名を返す' do
            expect(feature.feature_name).to eq feature_name
          end
        end

        context 'verboseにtrueが指定された場合' do
          it '副フィーチャー名込みの、フィーチャー名を返す' do
            expect(feature.feature_name(verbose: true)).to eq "#{feature_name}:#{sub_feature_name}"
          end
        end
      end

      context '副フィーチャー名が設定されていない場合' do
        it 'verboseの指定に関わらず、フィーチャー名を返す' do
          expect(feature.feature_name).to eq feature_name
          expect(feature.feature_name(verbose: true)).to eq feature_name
        end
      end
    end

    describe '.define_helpers' do
      before do
        feature_class.class_exec do
          define_helpers do
            def foo ; :foo; end
            def bar ; :bar; end
          end
        end
      end

      it '特異クラスにヘルパーメソッドを追加する' do
        expect(feature_class.singleton_methods(false)).to contain_exactly :foo, :bar
      end

      specify '#helperヘルパーメソッドを参照できる' do
        expect(feature.instance_eval { helper.foo }).to eq :foo
        expect(feature.instance_eval { helper.bar }).to eq :bar
      end
    end

    describe '#available?' do
      context '通常の場合' do
        it '使用可能であることを示す' do
          expect(feature).to be_available
        end
      end

      context '.available?で#available?が再定義された場合' do
        before do
          feature_class.class_exec do
            available? { false }
          end
        end

        it 'available?に与えたブロックの評価結果を返す' do
          expect(feature).not_to be_available
        end
      end
    end
  end
end
