require 'spec_helper'

module RgGen::Core::OutputBase
  describe FileWriter do
    def create_file_writer(pattern, &block)
      FileWriter.new(pattern, block || nil)
    end

    def create_context(&body)
      Class.new {
        def create_blank_file(_); ''.dup; end
        class_exec(&body)
      }.new
    end

    describe "#write_file" do
      let(:foo_context) do
        create_context do
          def contents; 'foo!'.dup; end
          def file_name; 'foo'.dup; end
        end
      end

      let(:bar_context) do
        create_context do
          def contents; 'bar!'.dup; end
          def file_name; 'bar/bar'.dup; end
        end
      end

      it "コード生成ブロックをコンテキスト上で実行し、その結果をファイルに書き出す" do
        writer = create_file_writer('test.txt') { |code| code << contents }

        expect(File).to receive(:binwrite).with(match_string('test.txt'), match_string('foo!'))
        writer.write_file(foo_context)

        expect(File).to receive(:binwrite).with(match_string('test.txt'), match_string('bar!'))
        writer.write_file(bar_context)
      end

      it "パターンをコンテキスト上で実行し、その結果をファイル名とする" do
        writer = create_file_writer('<%= file_name %>.txt')

        expect(File).to receive(:binwrite).with(match_string('foo.txt'), any_args)
        writer.write_file(foo_context)

        expect(File).to receive(:binwrite).with(match_string('bar/bar.txt'), any_args)
        writer.write_file(bar_context)
      end

      context "出力ディレクトリが指定された場合" do
        it "指定されたディレクトリに、フィアルを書き出す" do
          writer = create_file_writer('test.txt')

          expect(File).to receive(:binwrite).with(match_string('test.txt'), any_args)
          writer.write_file(foo_context, '')

          expect(File).to receive(:binwrite).with(match_string('foo/test.txt'), any_args)
          writer.write_file(foo_context, 'foo')

          expect(File).to receive(:binwrite).with(match_string('foo/test.txt'), any_args)
          writer.write_file(foo_context, :foo)

          expect(File).to receive(:binwrite).with(match_string('foo/bar/test.txt'), any_args)
          writer.write_file(foo_context, 'foo/bar')

          expect(File).to receive(:binwrite).with(match_string('foo/bar/test.txt'), any_args)
          writer.write_file(foo_context, ['foo', :bar])
        end
      end

      context "出力ディレクトリがない場合" do
        before do
          allow(File).to receive(:binwrite)
          allow_any_instance_of(Pathname).to receive(:directory?).and_return(false)
        end

        it "ディレクトリを作る" do
          writer = create_file_writer('foo/text.txt')

          expect(FileUtils).to receive(:mkpath).with(match_string('foo'))
          writer.write_file(foo_context)

          expect(FileUtils).to receive(:mkpath).with(match_string('bar/foo'))
          writer.write_file(foo_context, 'bar')
        end
      end
    end
  end
end
