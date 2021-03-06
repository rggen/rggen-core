# frozen_string_literal: true

RSpec.describe RgGen::Core::OutputBase::CodeGenerator do
  def create_generator
    generator = described_class.new
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

  let(:code) do
    c = double('code')
    allow(c).to receive(:<<)
    c
  end

  describe '#generate' do
    it '#registerで登録されたブロックをコンテキスト上で実行して、コードの生成を行う' do
      generator = create_generator do |g|
        g.register(:foo) { |c| c << foo }
        g.register(:bar) { bar }
      end

      expect(context).to receive(:foo).and_call_original
      expect(code).to receive(:<<).with('foo')
      generator.generate(context, code, :foo)

      expect(context).to receive(:bar).and_call_original
      expect(code).to receive(:<<).with('bar')
      generator.generate(context, code, :bar)
    end

    specify '同名のコード生成ブロックを複数個登録できる' do
      generator = create_generator do |g|
        g.register(:foo) { foo * 1 }
        g.register(:foo) { foo * 2 }
        g.register(:foo) { foo * 3 }
      end

      expect(code).to receive(:<<).with('foo')
      expect(code).to receive(:<<).with('foofoo')
      expect(code).to receive(:<<).with('foofoofoo')
      generator.generate(context, code, :foo)
    end

    context '登録されたコード生成ブロックが指定されなかった場合' do
      let(:generator) do
        create_generator do |g|
          g.register(:foo) { foo }
        end
      end

      it 'エラーなく実行される' do
        expect {
          generator.generate(context, code, :bar)
        }.not_to raise_error
      end

      it 'コードの追加は行わない' do
        expect(code).not_to receive(:<<)
        generator.generate(context, code, :bar)
      end
    end

    context 'コード生成ブロックが未登録の場合' do
      let(:generator) { create_generator }

      it 'エラーなく実行される' do
        expect {
          generator.generate(context, code, :bar)
        }.not_to raise_error
      end

      it 'コードの追加は行わない' do
        expect(code).not_to receive(:<<)
        generator.generate(context, code, :bar)
      end
    end
  end

  context '#copy' do
    let(:foo_generator) do
      create_generator do |g|
        g.register(:foo) { foo }
        g.register(:bar) { bar }
      end
    end

    it '登録済みのコード生成ブロックを引き継ぐコピーを作成する' do
      bar_generator = foo_generator.copy

      expect(code).to receive(:<<).with('foo')
      bar_generator.generate(context, code, :foo)

      expect(code).to receive(:<<).with('bar')
      bar_generator.generate(context, code, :bar)
    end

    specify 'コピー変更は、コピー元に影響しない' do
      bar_generator = foo_generator.copy
      bar_generator.register(:foo) { foo * 2 }

      expect(code).to receive(:<<).with('foo')
      expect(code).to receive(:<<).with('foofoo')
      bar_generator.generate(context, code, :foo)

      expect(code).to receive(:<<).with('foo')
      expect(code).not_to receive(:<<).with('foofoo')
      foo_generator.generate(context, code, :foo)
    end
  end
end
