# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::OutputBase
  describe Component do
    let(:configuration) do
      RgGen::Core::Configuration::Component.new(nil)
    end

    let(:register_map) do
      RgGen::Core::RegisterMap::Component.new(nil, configuration)
    end

    def create_component(parent)
      component = Component.new(parent, configuration, register_map)
      parent && parent.add_child(component)
      component
    end

    def define_and_create_feature(component, feature_name, super_class = nil, &body)
      feature = Class.new(super_class || Feature, &body).new(component, feature_name)
      component.add_feature(feature)
      feature
    end

    it "レジスタマップオブジェクトの各プロパティドメソッドを呼び出すことができる" do
      allow(register_map).to receive(:properties).and_return([:foo, :bar, :baz])
      expect(register_map).to receive(:foo)
      expect(register_map).to receive(:bar)
      expect(register_map).to receive(:baz)

      component = create_component(nil)
      component.foo
      component.bar
      component.baz
    end

    it '.exportで指定されたフィーチャーのメソッドを呼び出すことができる' do
      component = create_component(nil)

      foo_feature = define_and_create_feature(component, :foo) do
        export :foo_0
        export :foo_1
      end
      bar_feature = define_and_create_feature(component, :bar) do
        export :bar_0
        export :bar_1
      end

      expect(foo_feature).to receive(:foo_0)
      expect(foo_feature).to receive(:foo_1)
      expect(bar_feature).to receive(:bar_0)
      expect(bar_feature).to receive(:bar_1)

      component.foo_0
      component.foo_1
      component.bar_0
      component.bar_1
    end

    describe "#need_children?" do
      let(:component) { create_component(nil) }

      context "レジスタマップオブジェクトが子コンポーネントを必要とする場合" do
        specify "同様に子コンポーネントを必要とする" do
          allow(register_map).to receive(:need_children?).and_return(true)
          expect(component.need_children?).to be true
        end
      end

      context "レジスタマップオブジェクトが子コンポーネントを必要としない場合" do
        specify "同様に子コンポーネントを必要としない" do
          allow(register_map).to receive(:need_children?).and_return(false)
          expect(component.need_children?).to be false
        end
      end
    end

    describe '#register_blocks?/#registers?/#bit_fields?' do
      let(:children) { [] }

      before do
        allow(register_map).to receive(:children).and_return(children)
      end

      it '下位階層を含むかどうかを示す' do
        components = []
        components << create_component(nil)
        components << create_component(components[0])
        components << create_component(components[1])

        expect(components[0].register_blocks?).to eq false
        expect(components[1].registers?).to eq false
        expect(components[2].bit_fields?).to eq false

        children << Object.new

        expect(components[0].register_blocks?).to eq true
        expect(components[1].registers?).to eq true
        expect(components[2].bit_fields?).to eq true
      end
    end

    describe '#pre_build' do
      let(:component) do
        create_component(nil)
      end

      let(:child_component) do
        create_component(component)
      end

      let(:features) do
        [
          define_and_create_feature(component, :foo_0) {},
          define_and_create_feature(component, :foo_1) {},
          define_and_create_feature(child_component, :bar_0) {},
          define_and_create_feature(child_component, :bar_1) {}
        ]
      end

      it '自身に属するフィーチャーの#pre_buildを呼び出して、事前組み立てを行う' do
        expect(features[0]).to receive(:pre_build)
        expect(features[1]).to receive(:pre_build)
        expect(features[2]).not_to receive(:pre_build)
        expect(features[3]).not_to receive(:pre_build)
        component.pre_build
      end
    end

    describe "#build" do
      let(:foo_component) do
        create_component(nil)
      end

      let(:bar_components) do
        Array.new(2) { create_component(foo_component) }
      end

      let(:baz_components) do
        bar_components.flat_map do |bar_component|
          Array.new(2) { create_component(bar_component) }
        end
      end

      let(:foo_features) do
        [
          define_and_create_feature(foo_component, :foo_0) { build { export :foo_0 } },
          define_and_create_feature(foo_component, :foo_1) { build { export :foo_1 } }
        ]
      end

      let(:bar_features) do
        bar_components.flat_map do |bar_component|
          [
            define_and_create_feature(bar_component, :bar_0),
            define_and_create_feature(bar_component, :bar_1)
          ]
        end
      end

      let(:baz_features) do
        baz_components.flat_map do |baz_component|
          [
            define_and_create_feature(baz_component, :baz_0),
            define_and_create_feature(baz_component, :baz_1)
          ]
        end
      end

      it "配下の全コンポーネント/フィーチャーの#buildを呼び出して、自身の組み立てを行う" do
        [*bar_components, *baz_components].each do |component|
          expect(component).to receive(:build).and_call_original
        end
        [*foo_features, *bar_features, *baz_features].each do |feature|
          expect(feature).to receive(:build).and_call_original
        end
        foo_component.build
      end

      specify "#build実行後、Feature#exportで指定されたメソッドを、自身をレシーバとして呼び出すことができる" do
        expect { foo_component.foo_0 }.to raise_error NoMethodError
        expect { foo_component.foo_1 }.to raise_error NoMethodError

        expect(foo_features[0]).to receive(:foo_0)
        expect(foo_features[1]).to receive(:foo_1)
        foo_component.build

        foo_component.foo_0
        foo_component.foo_1
      end
    end

    describe "#generate_code" do
      let(:code) { double('code') }

      let(:foo_component) do
        create_component(nil)
      end

      let(:bar_components) do
        Array.new(2) { create_component(foo_component) }
      end

      let(:baz_components) do
        bar_components.flat_map do |bar_component|
          Array.new(2) { create_component(bar_component) }
        end
      end

      before do
        allow_any_instance_of(Feature).to receive(:create_blank_code).and_return(code)
      end

      before do
        fizz_body = proc do
          main_code(:fizz) { "#{component.object_id}_#{'fizz' * (component.level + 1)}" }
        end
        buzz_body = proc do
          main_code(:buzz) { "#{component.object_id}_#{'buzz' * (component.level + 1)}" }
        end

        define_and_create_feature(foo_component, :fizz, &fizz_body)
        define_and_create_feature(foo_component, :buzz, &buzz_body)

        bar_components.each do |bar_component|
          define_and_create_feature(bar_component, :fizz, &fizz_body)
          define_and_create_feature(bar_component, :buzz, &buzz_body)
        end

        baz_components.each do |baz_component|
          define_and_create_feature(baz_component, :fizz, &fizz_body)
          define_and_create_feature(baz_component, :buzz, &buzz_body)
        end
      end

      context "modeに:top_downを指定した場合" do
        it "kindで指定したコードを上位コンポーネントから生成する" do
          [
            "#{foo_component.object_id}_fizz",
            "#{bar_components[0].object_id}_fizzfizz",
            "#{baz_components[0].object_id}_fizzfizzfizz",
            "#{baz_components[1].object_id}_fizzfizzfizz",
            "#{bar_components[1].object_id}_fizzfizz",
            "#{baz_components[2].object_id}_fizzfizzfizz",
            "#{baz_components[3].object_id}_fizzfizzfizz"
          ].each do |expected_code|
            expect(code).to receive(:<<).with(expected_code).ordered
          end
          foo_component.generate_code(:fizz, :top_down)

          [
            "#{foo_component.object_id}_buzz",
            "#{bar_components[0].object_id}_buzzbuzz",
            "#{baz_components[0].object_id}_buzzbuzzbuzz",
            "#{baz_components[1].object_id}_buzzbuzzbuzz",
            "#{bar_components[1].object_id}_buzzbuzz",
            "#{baz_components[2].object_id}_buzzbuzzbuzz",
            "#{baz_components[3].object_id}_buzzbuzzbuzz"
          ].each do |expected_code|
            expect(code).to receive(:<<).with(expected_code).ordered
          end
          foo_component.generate_code(:buzz, :top_down, code)
        end
      end

      context "modeに:bottom_upを指定した場合" do
        it "kindで指定したコードを下位コンポーネントから生成する" do
          [
            "#{baz_components[0].object_id}_fizzfizzfizz",
            "#{baz_components[1].object_id}_fizzfizzfizz",
            "#{bar_components[0].object_id}_fizzfizz",
            "#{baz_components[2].object_id}_fizzfizzfizz",
            "#{baz_components[3].object_id}_fizzfizzfizz",
            "#{bar_components[1].object_id}_fizzfizz",
            "#{foo_component.object_id}_fizz"
          ].each do |expected_code|
            expect(code).to receive(:<<).with(expected_code).ordered
          end
          foo_component.generate_code(:fizz, :bottom_up)

          [
            "#{baz_components[0].object_id}_buzzbuzzbuzz",
            "#{baz_components[1].object_id}_buzzbuzzbuzz",
            "#{bar_components[0].object_id}_buzzbuzz",
            "#{baz_components[2].object_id}_buzzbuzzbuzz",
            "#{baz_components[3].object_id}_buzzbuzzbuzz",
            "#{bar_components[1].object_id}_buzzbuzz",
            "#{foo_component.object_id}_buzz"
          ].each do |expected_code|
            expect(code).to receive(:<<).with(expected_code).ordered
          end
          foo_component.generate_code(:buzz, :bottom_up, code)
        end
      end

      it "内部で生成したコードオブジェクト、または、与えたコードオブジェクトを返す" do
        allow(code).to receive(:<<)
        expect(foo_component.generate_code(:fizz, :top_down)).to eq code
        expect(foo_component.generate_code(:fizz, :top_down, code)).to eq code
        expect(foo_component.generate_code(:fizz, :bottom_up)).to eq code
        expect(foo_component.generate_code(:fizz, :bottom_up, code)).to eq code
      end

      context "Feature.pre_codeで事前コード生成の登録がある場合" do
        before do
          pre_fizz_0_body = proc do
            pre_code(:fizz) { "#{component.object_id}_pre_#{'fizz' * (component.level + 1)}_0" }
          end
          pre_fizz_1_body = proc do
            pre_code(:fizz) { "#{component.object_id}_pre_#{'fizz' * (component.level + 1)}_1" }
          end

          define_and_create_feature(foo_component, :pre_fizz_0, &pre_fizz_0_body)
          define_and_create_feature(foo_component, :pre_fizz_1, &pre_fizz_1_body)

          bar_components.each do |bar_component|
            define_and_create_feature(bar_component, :pre_fizz_0, &pre_fizz_0_body)
            define_and_create_feature(bar_component, :pre_fizz_1, &pre_fizz_1_body)
          end
        end

        it "Feature.main_codeで登録された主コード生成前に、事前コードを生成する" do
          [
            "#{foo_component.object_id}_pre_fizz_0",
            "#{foo_component.object_id}_pre_fizz_1",
            "#{foo_component.object_id}_fizz",
            "#{bar_components[0].object_id}_pre_fizzfizz_0",
            "#{bar_components[0].object_id}_pre_fizzfizz_1",
            "#{bar_components[0].object_id}_fizzfizz",
            "#{baz_components[0].object_id}_fizzfizzfizz",
            "#{baz_components[1].object_id}_fizzfizzfizz",
            "#{bar_components[1].object_id}_pre_fizzfizz_0",
            "#{bar_components[1].object_id}_pre_fizzfizz_1",
            "#{bar_components[1].object_id}_fizzfizz",
            "#{baz_components[2].object_id}_fizzfizzfizz",
            "#{baz_components[3].object_id}_fizzfizzfizz"
          ].each do |expected_code|
            expect(code).to receive(:<<).with(expected_code).ordered
          end
          foo_component.generate_code(:fizz, :top_down, code)

          [
            "#{foo_component.object_id}_pre_fizz_0",
            "#{foo_component.object_id}_pre_fizz_1",
            "#{bar_components[0].object_id}_pre_fizzfizz_0",
            "#{bar_components[0].object_id}_pre_fizzfizz_1",
            "#{baz_components[0].object_id}_fizzfizzfizz",
            "#{baz_components[1].object_id}_fizzfizzfizz",
            "#{bar_components[0].object_id}_fizzfizz",
            "#{bar_components[1].object_id}_pre_fizzfizz_0",
            "#{bar_components[1].object_id}_pre_fizzfizz_1",
            "#{baz_components[2].object_id}_fizzfizzfizz",
            "#{baz_components[3].object_id}_fizzfizzfizz",
            "#{bar_components[1].object_id}_fizzfizz",
            "#{foo_component.object_id}_fizz"
          ].each do |expected_code|
            expect(code).to receive(:<<).with(expected_code).ordered
          end
          foo_component.generate_code(:fizz, :bottom_up, code)
        end
      end

      context "Feature.post_codeで事後コード生成の登録がある場合" do
        before do
          post_fizz_0_body = proc do
            post_code(:fizz) { "#{component.object_id}_post_#{'fizz' * (component.level + 1)}_0" }
          end
          post_fizz_1_body = proc do
            post_code(:fizz) { "#{component.object_id}_post_#{'fizz' * (component.level + 1)}_1" }
          end

          define_and_create_feature(foo_component, :post_fizz_0, &post_fizz_0_body)
          define_and_create_feature(foo_component, :post_fizz_1, &post_fizz_1_body)

          bar_components.each do |bar_component|
            define_and_create_feature(bar_component, :post_fizz_0, &post_fizz_0_body)
            define_and_create_feature(bar_component, :post_fizz_1, &post_fizz_1_body)
          end
        end

        it "Feature.main_codeで登録された主コードの生成後に、事後コードを生成する" do
          [
            "#{foo_component.object_id}_fizz",
            "#{bar_components[0].object_id}_fizzfizz",
            "#{baz_components[0].object_id}_fizzfizzfizz",
            "#{baz_components[1].object_id}_fizzfizzfizz",
            "#{bar_components[0].object_id}_post_fizzfizz_0",
            "#{bar_components[0].object_id}_post_fizzfizz_1",
            "#{bar_components[1].object_id}_fizzfizz",
            "#{baz_components[2].object_id}_fizzfizzfizz",
            "#{baz_components[3].object_id}_fizzfizzfizz",
            "#{bar_components[1].object_id}_post_fizzfizz_0",
            "#{bar_components[1].object_id}_post_fizzfizz_1",
            "#{foo_component.object_id}_post_fizz_0",
            "#{foo_component.object_id}_post_fizz_1"
          ].each do |expected_code|
            expect(code).to receive(:<<).with(expected_code).ordered
          end
          foo_component.generate_code(:fizz, :top_down, code)

          [
            "#{baz_components[0].object_id}_fizzfizzfizz",
            "#{baz_components[1].object_id}_fizzfizzfizz",
            "#{bar_components[0].object_id}_fizzfizz",
            "#{bar_components[0].object_id}_post_fizzfizz_0",
            "#{bar_components[0].object_id}_post_fizzfizz_1",
            "#{baz_components[2].object_id}_fizzfizzfizz",
            "#{baz_components[3].object_id}_fizzfizzfizz",
            "#{bar_components[1].object_id}_fizzfizz",
            "#{bar_components[1].object_id}_post_fizzfizz_0",
            "#{bar_components[1].object_id}_post_fizzfizz_1",
            "#{foo_component.object_id}_fizz",
            "#{foo_component.object_id}_post_fizz_0",
            "#{foo_component.object_id}_post_fizz_1"
          ].each do |expected_code|
            expect(code).to receive(:<<).with(expected_code).ordered
          end
          foo_component.generate_code(:fizz, :bottom_up, code)
        end
      end
    end

    describe "#write_file" do
      let(:foo_component) do
        create_component(nil)
      end

      let(:bar_components) do
        Array.new(2) { create_component(foo_component) }
      end

      let(:feature_base) do
        Class.new(Feature) do
          def create_blank_file(_path); ''.dup; end
        end
      end

      let(:foo_feature) do
        define_and_create_feature(foo_component, :foo_feature, feature_base) do
          write_file('<%= file_name %>') { |f| f << file_content }
          def file_name; "#{component.object_id}_foo.txt"; end
          def file_content; "#{component.object_id} foo !"; end
        end
      end

      let(:bar_features) do
        bar_components.map.with_index do |bar_component, i|
          define_and_create_feature(bar_component, :bar_feature, feature_base) do
            write_file('<%= file_name %>') { |f| f << file_content }
            define_method(:file_name) { "#{component.object_id}_bar_#{i}.txt" }
            define_method(:file_content) { "#{component.object_id} bar #{i} !" }
          end
        end
      end

      it "配下の全フィーチャーの#write_fileを呼び出して、ファイルの書き出しを行う" do
        [foo_feature, *bar_features].each do |feature|
          expect(feature).to receive(:write_file).and_call_original
          expect(File).to receive(:binwrite).with(match_string(feature.file_name), feature.file_content)
        end
        foo_component.write_file

        [foo_feature, *bar_features].each do |feature|
          expect(feature).to receive(:write_file).and_call_original
          expect(File).to receive(:binwrite).with(match_string("foo/bar/#{feature.file_name}"), feature.file_content)
        end
        foo_component.write_file(['foo', 'bar'])
      end
    end
  end
end
