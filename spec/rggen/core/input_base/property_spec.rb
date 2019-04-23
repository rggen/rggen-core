# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::InputBase
  ::RSpec.describe Property do
    describe '.define' do
      def create_feature(&body)
        Class.new(&body).new
      end

      def define_property(feature, name, **options, &body)
        Property.define(feature.class, name, **options, &body)
      end

      context 'プロパティ名のみ与えられた場合' do
        let(:feature) do
          create_feature do
            def initialize; @foo = 1; end
          end
        end

        it '同名のフィーチャー上のインスタンス変数を返すプロパティを定義する' do
          define_property(feature, :foo)
          expect(feature.foo).to eq 1
        end
      end

      context '末尾に ? が付くプロパティ名が与えられた場合' do
        let(:feature) do
          create_feature do
            def initialize; @foo = 1; end
          end
        end

        it '同名(?は除く)のフィーチャー上のインスタンス変数を返すプロパティを定義する' do
          define_property(feature, :foo?)
          expect(feature.foo?).to eq 1
        end
      end

      context 'ブロックが与えられた場合' do
        let(:feature) do
          create_feature do
            def initialize; @foo = 1; end
            def bar; 2; end
          end
        end

        it 'ブロックをフィーチャ上で実行するプロパティを定義する' do
          define_property(feature, :foo) { @foo }
          expect(feature.foo).to eq 1

          define_property(feature, :barbar) { 2 * bar }
          expect(feature.barbar).to eq 4
        end

        specify '定義されたプロパティは引数、ブロックを取れる' do
          define_property(feature, :foo) { |v, &b| v + b.call }
          expect(feature.foo(2) { 3 }).to eq 5
        end
      end

      describe 'bodyオプション' do
        let(:feature) do
          create_feature do
            def initialize; @foo = 1; end
            def bar; 2; end
          end
        end

        it 'ブロックをフィーチャ上で実行するプロパティを定義する' do
          define_property(feature, :foo, body: -> { @foo })
          expect(feature.foo).to eq 1

          define_property(feature, :barbar, body: ->  { 2 * bar })
          expect(feature.barbar).to eq 4
        end

        specify '定義されたプロパティは引数、ブロックを取れる' do
          define_property(feature, :foo, body: ->(v, &b) { v + b.call })
          expect(feature.foo(2) { 3 }).to eq 5
        end
      end

      describe 'defaultオプション' do
        let(:feature) do
          create_feature do
            def set_foo; @foo = 1; end
            def set_bar; @bar = true; end
          end
        end

        it 'プロパティの既定値を指定する' do
          define_property(feature, :foo, default: 0)
          expect(feature.foo).to eq 0
          feature.set_foo
          expect(feature.foo).to eq 1

          define_property(feature, :bar?, default: false)
          expect(feature.bar?).to be false
          feature.set_bar
          expect(feature.bar?).to be true
        end
      end

      describe 'forward_to_helper' do
        let(:feature) do
          create_feature do
            class << self
              def foo; 2; end
              def bar(v, &b); v + b.call; end
            end

            def initialize; @foo = 1; end
          end
        end

        context 'trueが指定された場合' do
          it 'ヘルパーメソッドに委譲するプロパティを定義する' do
            define_property(feature, :foo, forward_to_helper: true)
            expect(feature.foo).to eq 2
          end

          specify '定義されるプロパティは引数とブロックを取ることができる' do
            define_property(feature, :bar, forward_to_helper: true)
            expect(feature.bar(2) { 3 }).to eq 5
          end
        end

        context 'falseが指定された場合' do
          it '通常のプロパティを定義する' do
            define_property(feature, :foo, forward_to_helper: false)
            expect(feature.class).not_to receive(:foo)
            expect(feature.foo).to eq 1
          end
        end
      end

      describe 'forward_toオプション' do
        let(:feature) do
          create_feature do
            def foo; 1; end
            def bar(v, &b); v + b.call; end
          end
        end

        it '指定されたメソッドに委譲するプロパティを定義する' do
          define_property(feature, :foofoo, forward_to: :foo)
          expect(feature).to receive(:foo).and_call_original
          expect(feature.foofoo).to eq 1
        end

        specify '定義されるプロパティは引数とブロックを取ることができる' do
          define_property(feature, :barbar, forward_to: :bar)
          expect(feature.barbar(2) { 3 }).to eq 5
        end
      end
    end
  end
end
