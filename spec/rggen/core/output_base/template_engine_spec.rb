# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::OutputBase
  describe TemplateEngine do
    let(:template_engine) do
      klass = Class.new(TemplateEngine) do
        def file_extension
          :erb
        end
        def parse_template(path)
          Erubi::Engine.new(File.binread(path))
        end
        def render(context, template)
          context.instance_eval(template.src)
        end
      end
      klass.instance
    end

    let(:contexts) do
      klass = Class.new do
        def initialize(v)
          @v = v
        end
        def foo
          "#{@v} foo"
        end
        def bar
          "#{@v} bar"
        end
      end
      Hash.new {|h, v| h[v] = klass.new(v) }
    end

    def set_teamplate_contents(contents)
      contents.each do |path, content|
        expect(File).to receive(:binread).with(path).once.and_return(content)
      end
    end

    describe '#process_template' do
      it "与えられたコンテキスト上で、テンプレートを処理する" do
        set_teamplate_contents(
          'foo.erb' => '<%= object_id %> <%= foo %>',
          'bar.erb' => '<%= object_id %> <%= bar %>'
        )

        expect(template_engine.process_template(contexts[0], 'foo.erb')).to eq "#{contexts[0].object_id} #{contexts[0].foo}"
        expect(template_engine.process_template(contexts[0], 'bar.erb')).to eq "#{contexts[0].object_id} #{contexts[0].bar}"

        expect(template_engine.process_template(contexts[1], 'foo.erb')).to eq "#{contexts[1].object_id} #{contexts[1].foo}"
        expect(template_engine.process_template(contexts[1], 'bar.erb')).to eq "#{contexts[1].object_id} #{contexts[1].bar}"
      end

      context "テンプレートのパスが未指定で" do
        let(:template_path) do
          File.ext(File.expand_path(__FILE__), '.erb')
        end

        context "呼び出し元情報も未指定の場合" do
          it "呼び出し元のファイルの拡張子を対象拡張子 (#file_extension) に変更したものをテンプレートのパスとして、テンプレートを処理する" do
            set_teamplate_contents(template_path => '<%= foo %> <%= bar %>')
            expect(template_engine.process_template(contexts[0])).to eq "#{contexts[0].foo} #{contexts[0].bar}"
          end
        end

        context "呼び出し元情報が指定されている場合" do
          it "呼び出し元情報からファイルのパスを取り出し、拡張子を変更したパスをテンプレートのパスとして、テンプレートを処理する" do
            set_teamplate_contents(template_path => '<%= foo %> <%= bar %>')
            caller_location = double('caller_location')
            allow(caller_location).to receive(:path).and_return(template_path)
            expect(template_engine.process_template(contexts[0], nil, caller_location)).to eq "#{contexts[0].foo} #{contexts[0].bar}"
          end
        end
      end
    end
  end
end
