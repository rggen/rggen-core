# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::OutputBase
  describe CodeGenerator do
    def create_generator
      generator = CodeGenerator.new
      block_given? && yield(generator)
      generator
    end

    let(:context) do
      klass = Class.new do
        def foo; 'foo'; end
        def bar; 'bar'; end
      end
      klass.new
    end

    let(:code) { double('code') }

    describe '#generate' do
      context "#register で登録されたコード生成ブロックが指定された場合" do
        let(:generator) do
          create_generator do |g|
            g.register(:foo, (proc { |c| c << foo }))
            g.register(:bar, (proc { bar }))
          end
        end

        it '与えられたコンテキスト上でコード生成ブロックを実行し、コードの生成を行う' do
          expect(code).to receive(:<<).with('foo')
          generator.generate(context, :foo, code)

          expect(code).to receive(:<<).with('bar')
          generator.generate(context, :bar, code)
        end

        it '使用されたコードオブジェクトを返す' do
          allow(code).to receive(:<<)
          expect(generator.generate(context, :foo, code)).to be code
          expect(generator.generate(context, :bar, code)).to be code
        end
      end

      context "与えらた code が nil の場合" do
        let(:generator) do
          create_generator do |g|
            g.register(:foo, proc { |c| c << foo })
            g.register(:bar, proc { |c| bar })
          end
        end

        before do
          allow(code).to receive(:<<)
        end

        it "context の #create_blank_code を呼び出して、コードオブジェクトを生成する" do
          expect(context).to receive(:create_blank_code).and_return(code)
          generator.generate(context, :foo, nil)
        end

        it "生成したコードオブジェクトを返す" do
          allow(context).to receive(:create_blank_code).and_return(code)
          expect(generator.generate(context, :foo, nil)).to be code
          expect(generator.generate(context, :bar, nil)).to be code
        end
      end

      context "登録されたコード生成ブロックが指定されなかった場合" do
        let(:generator) do
          create_generator do |g|
            g.register(:foo, proc { foo })
          end
        end

        it "エラーなく実行される" do
          expect {
            generator.generate(context, :bar, code)
          }.not_to raise_error
          expect {
            generator.generate(context, :bar, nil)
          }.not_to raise_error
        end

        it "コードの追加は行わない" do
          expect(code).not_to receive(:<<)
          generator.generate(context, :bar, code)
        end

        it "コードの生成は行わない" do
          expect(context).not_to receive(:create_blank_code)
          generator.generate(context, :bar, nil)
        end

        it "与えたコードオブジェクトを返す" do
          expect(generator.generate(context, :bar, code)).to be code
          expect(generator.generate(context, :bar, nil)).to be nil
        end
      end

      context "コード生成ブロックが未登録の場合" do
        let(:generator) { create_generator }

        it "エラーなく実行される" do
          expect {
            generator.generate(context, :bar, code)
          }.not_to raise_error
          expect {
            generator.generate(context, :bar, nil)
          }.not_to raise_error
        end

        it "コードの追加は行わない" do
          expect(code).not_to receive(:<<)
          generator.generate(context, :bar, code)
        end

        it "コードの生成は行わない" do
          expect(context).not_to receive(:create_blank_code)
          generator.generate(context, :bar, nil)
        end

        it "与えたコードオブジェクトを返す" do
          expect(generator.generate(context, :bar, code)).to be code
          expect(generator.generate(context, :bar, nil)).to be nil
        end
      end
    end

    context "#copy" do
      let(:foo_generator) do
        create_generator do |g|
          g.register(:foo, proc { foo })
          g.register(:bar, proc { bar })
        end
      end

      it "登録済みのコード生成ブロックを引き継ぐコピーを作成する" do
        bar_generator = foo_generator.copy

        expect(code).to receive(:<<).with('foo')
        bar_generator.generate(context, :foo, code)

        expect(code).to receive(:<<).with('bar')
        bar_generator.generate(context, :bar, code)
      end

      specify 'コピー変更は、コピー元に影響しない' do
        bar_generator = foo_generator.copy
        bar_generator.register(:foo, proc { foo * 2 })

        expect(code).to receive(:<<).with('foofoo')
        bar_generator.generate(context, :foo, code)

        expect(code).to receive(:<<).with('foo')
        foo_generator.generate(context, :foo, code)
      end
    end
  end
end
