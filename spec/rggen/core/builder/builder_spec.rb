# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::Builder
  describe Builder do
    let(:builder) { Builder.new }

    let(:categories) { {} }

    let(:component_registries) { {} }

    let(:feature_registries) { [] }

    before do
      allow(Category).to receive(:new).and_wrap_original do |m, *args|
        m.call(*args).tap { |category| categories[args.first] = category }
      end

      allow(InputComponentRegistry).to receive(:new).and_wrap_original do |m, *args|
        m.call(*args).tap { |registry| component_registries[args.first] = registry }
      end

      allow(OutputComponentRegistry).to receive(:new).and_wrap_original do |m, *args|
        m.call(*args).tap { |registry| component_registries[args.first] = registry }
      end

      allow(FeatureRegistry).to receive(:new).and_wrap_original do |m, *args|
        m.call(*args).tap { |registry| feature_registries << registry }
      end

      builder
    end

    specify "初期化時に global/register_map/register_block/register/bit_field のカテゴリが作られる" do
      expect(categories.keys).to match([:global, :register_map, :register_block, :register, :bit_field])
    end

    describe "#input_component_registry" do
      it "入力コンポーネントを登録する" do
        expect {
          builder.input_component_registry(:configuration) do
            register_component do
              component(
                RgGen::Core::Configuration::Component,
                RgGen::Core::Configuration::ComponentFactory
              )
            end
          end
        }.to change { component_registries.size }.from(0).to(1)
      end

      specify "入力コンポーネントの登録の生成は一度のみ行われる" do
        builder.input_component_registry(:register_map) do
          register_component do
            component(
              RgGen::Core::RegisterMap::Component,
              RgGen::Core::RegisterMap::ComponentFactory
            )
          end
        end

        expect {
          builder.input_component_registry(:register_map) do
            register_component(:register_block) do
              component(
                RgGen::Core::RegisterMap::Component,
                RgGen::Core::RegisterMap::ComponentFactory
              )
            end
          end
        }.not_to change { component_registries.size }
      end

      context "フィーチャーの登録があり" do
        context "カテゴリの指定がない場合" do
          it "全カテゴリにフィーチャーの登録を追加する" do
            categories.each_value do |category|
              allow(category).to receive(:add_feature_registry).and_call_original
            end

            builder.input_component_registry(:configuration) do
              register_component do
                component(
                  RgGen::Core::Configuration::Component,
                  RgGen::Core::Configuration::ComponentFactory
                )
                feature(
                  RgGen::Core::Configuration::Feature,
                  RgGen::Core::Configuration::FeatureFactory
                )
              end
            end

            categories.each_value do |category|
              expect(category).to have_received(:add_feature_registry).with(:configuration, equal(feature_registries.first))
            end
          end
        end

        context "カテゴリの指定がある場合" do
          it "指定されたカテゴリにフィーチャーの登録を追加する" do
            categories.each do |name, category|
              if [:register_block, :register, :bit_field].include?(name)
                allow(category).to receive(:add_feature_registry).and_call_original
              else
                expect(category).not_to receive(:add_feature_registry)
              end
            end

            builder.input_component_registry(:register_map) do
              register_component(:register_block) do
                component(
                  RgGen::Core::RegisterMap::Component,
                  RgGen::Core::RegisterMap::ComponentFactory
                )
                feature(
                  RgGen::Core::RegisterMap::Feature,
                  RgGen::Core::RegisterMap::FeatureFactory
                )
              end

              register_component([:register, :bit_field]) do
                component(
                  RgGen::Core::RegisterMap::Component,
                  RgGen::Core::RegisterMap::ComponentFactory
                )
                feature(
                  RgGen::Core::RegisterMap::Feature,
                  RgGen::Core::RegisterMap::FeatureFactory
                )
              end
            end

            [:register_block, :register, :bit_field].each_with_index do |category, i|
              expect(categories[category]).to have_received(:add_feature_registry).with(:register_map, equal(feature_registries[i]))
            end
          end
        end
      end
    end

    describe "#output_component_registry" do
      it "出力コンポーネントを登録する" do
        expect {
          builder.output_component_registry(:foo) do
            register_component do
              component(
                RgGen::Core::OutputBase::Component,
                RgGen::Core::OutputBase::ComponentFactory
              )
            end
          end
        }.to change { component_registries.size }.from(0).to(1)
      end

      specify "出力コンポーネントの登録の生成は一度のみ行われる" do
        builder.output_component_registry(:foo) do
          register_component do
            component(
              RgGen::Core::OutputBase::Component,
              RgGen::Core::OutputBase::ComponentFactory
            )
          end
        end

        expect {
          builder.output_component_registry(:foo) do
            register_component(:register_block) do
              component(
                RgGen::Core::OutputBase::Component,
                RgGen::Core::OutputBase::ComponentFactory
              )
            end
          end
        }.not_to change { component_registries.size }
      end

      context "フィーチャーの登録があり" do
        context "カテゴリの指定がない場合" do
          it "全カテゴリにフィーチャーの登録を追加する" do
            categories.each_value do |category|
              allow(category).to receive(:add_feature_registry).and_call_original
            end

            builder.output_component_registry(:foo) do
              register_component do
                component(
                  RgGen::Core::OutputBase::Component,
                  RgGen::Core::OutputBase::ComponentFactory
                )
                feature(
                  RgGen::Core::OutputBase::Feature,
                  RgGen::Core::OutputBase::FeatureFactory
                )
              end
            end

            categories.each_value do |category|
              expect(category).to have_received(:add_feature_registry).with(:foo, equal(feature_registries.first))
            end
          end
        end

        context "カテゴリの指定がある場合" do
          it "指定されたカテゴリにフィーチャーの登録を追加する" do
            categories.each do |name, category|
              if [:register_block, :register, :bit_field].include?(name)
                allow(category).to receive(:add_feature_registry).and_call_original
              else
                expect(category).not_to receive(:add_feature_registry)
              end
            end

            builder.output_component_registry(:foo) do
              register_component(:register_block) do
                component(
                  RgGen::Core::RegisterMap::Component,
                  RgGen::Core::RegisterMap::ComponentFactory
                )
                feature(
                  RgGen::Core::RegisterMap::Feature,
                  RgGen::Core::RegisterMap::FeatureFactory
                )
              end

              register_component([:register, :bit_field]) do
                component(
                  RgGen::Core::RegisterMap::Component,
                  RgGen::Core::RegisterMap::ComponentFactory
                )
                feature(
                  RgGen::Core::RegisterMap::Feature,
                  RgGen::Core::RegisterMap::FeatureFactory
                )
              end
            end

            [:register_block, :register, :bit_field].each_with_index do |category, i|
              expect(categories[category]).to have_received(:add_feature_registry).with(:foo, equal(feature_registries[i]))
            end
          end
        end
      end
    end

    def default_component_registration
      builder.input_component_registry(:configuration) do
        register_component do
          component(
            RgGen::Core::Configuration::Component,
            RgGen::Core::Configuration::ComponentFactory
          )
          feature(
            RgGen::Core::Configuration::Feature,
            RgGen::Core::Configuration::FeatureFactory
          )
        end

        base_loader RgGen::Core::Configuration::Loader
      end

      builder.input_component_registry(:register_map) do
        register_component do
          component(
            RgGen::Core::RegisterMap::Component,
            RgGen::Core::RegisterMap::ComponentFactory
          )
        end
        register_component([:register_block, :register, :bit_field]) do
          component(
            RgGen::Core::RegisterMap::Component,
            RgGen::Core::RegisterMap::ComponentFactory
          )
          feature(
            RgGen::Core::RegisterMap::Feature,
            RgGen::Core::RegisterMap::FeatureFactory
          )
        end
        base_loader RgGen::Core::RegisterMap::Loader
      end

      [:foo, :bar, :baz].each do |component_name|
        builder.output_component_registry(component_name) do
          register_component do
            component(
              RgGen::Core::OutputBase::Component,
              RgGen::Core::OutputBase::ComponentFactory
            )
          end
          register_component([:register_block, :register, :bit_field]) do
            component(
              RgGen::Core::OutputBase::Component,
              RgGen::Core::OutputBase::ComponentFactory
            )
            feature(
              RgGen::Core::OutputBase::Feature,
              RgGen::Core::OutputBase::FeatureFactory
            )
          end
        end
      end
    end

    def default_feature_definitions(category)
      builder.define_simple_feature(category, [:fizz_0, :fizz_1, :fizz_2]) do
        configuration { |feature_name| define_method(feature_name) { feature_name } }
        if category != :global
          register_map { |feature_name| define_method(feature_name) { feature_name } }
          foo { |feature_name| define_method(feature_name) { feature_name } }
          bar { |feature_name| define_method(feature_name) { feature_name } }
          baz { |feature_name| define_method(feature_name) { feature_name } }
        end
      end

      builder.define_list_feature(category, :buzz) do
        configuration {}
        if category != :global
          register_map {}
          foo {}
          bar {}
          baz {}
        end
      end

      builder.define_list_item_feature(category, :buzz, [:buzz_0, :buzz_1, :buzz_2]) do
        configuration { |feature_name| define_method(feature_name) { feature_name } }
        if category != :global
          register_map { |feature_name| define_method(feature_name) { feature_name } }
          foo { |feature_name| define_method(feature_name) { feature_name } }
          bar { |feature_name| define_method(feature_name) { feature_name } }
          baz { |feature_name| define_method(feature_name) { feature_name } }
        end
      end
    end

    describe "#register_loader/#register_loaders/#define_loader" do
      before do
        default_component_registration
      end

      let(:target_component) do
        [:configuration, :register_map].sample
      end

      let(:component_registry) { component_registries[target_component] }

      let(:loaders) do
        if target_component == :configuration
          [
            RgGen::Core::Configuration::RubyLoader,
            RgGen::Core::Configuration::YAMLLoader,
            RgGen::Core::Configuration::JSONLoader
          ]
        else
          [
            RgGen::Core::RegisterMap::RubyLoader,
            RgGen::Core::RegisterMap::YAMLLoader,
            RgGen::Core::RegisterMap::JSONLoader
          ]
        end
      end

      it "対象コンポーネントローダーの追加/定義を行う" do
        allow(component_registry).to receive(:register_loader).and_call_original
        allow(component_registry).to receive(:register_loaders).and_call_original
        allow(component_registry).to receive(:define_loader).and_call_original

        builder.register_loader(target_component, loaders[0])
        builder.register_loaders(target_component, [loaders[1], loaders[2]])
        builder.define_loader(target_component) { support_types [:txt] }

        expect(component_registry).to have_received(:register_loader).with(equal(loaders[0]))
        expect(component_registry).to have_received(:register_loaders).with(match([equal(loaders[1]), equal(loaders[2])]))
        expect(component_registry).to have_received(:define_loader)
      end

      context "未登録のコンポーネントが指定された場合" do
        it "BuilderErrorを起こす" do
          expect {
            builder.register_loader(:foo, RgGen::Core::Configuration::YAMLLoader)
          }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown component: foo'

          expect {
            builder.register_loaders(
              :foo, [RgGen::Core::Configuration::YAMLLoader, RgGen::Core::Configuration::JSONLoader]
            )
          }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown component: foo'

          expect {
            builder.define_loader(:bar) { support_types [:txt] }
          }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown component: bar'
        end
      end
    end

    describe "#define_simple_feature/#define_list_feature" do
      let(:target_category) do
        [:global, :register_block, :register, :bit_field].sample
      end

      let(:category) { categories[target_category] }

      before do
        default_component_registration
      end

      it "指定したカテゴリの#define_simple_feature/#define_list_featureを呼び出して、フィーチャーの定義を行う" do
        expect(category).to receive(:define_simple_feature).with(:foo).and_call_original
        expect(category).to receive(:define_simple_feature).with(:bar, shared_context: true).and_call_original
        expect(category).to receive(:define_list_feature).with(:baz).and_call_original
        expect(category).to receive(:define_list_item_feature).with(:baz, :bar_0, shared_context: true).and_call_original
        expect(category).to receive(:define_list_feature).with(:qux, shared_context: true).and_call_original
        expect(category).to receive(:define_list_item_feature).with(:qux, :qux_0).and_call_original

        builder.define_simple_feature(target_category, :foo) {}
        builder.define_simple_feature(target_category, :bar, shared_context: true) {}
        builder.define_list_feature(target_category, :baz) {}
        builder.define_list_item_feature(target_category, :baz, :bar_0, shared_context: true) {}
        builder.define_list_feature(target_category, :qux, shared_context: true) {}
        builder.define_list_item_feature(target_category, :qux, :qux_0) {}
      end

      context "未定義のカテゴリが指定された場合" do
        it "BuilderErrorを起こす" do
          expect {
            builder.define_simple_feature(:foo, :bar) {}
          }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown category: foo'

          expect {
            builder.define_list_feature(:bar, :baz) {}
          }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown category: bar'

          expect {
            builder.define_list_feature(:baz, :qux, :qux_0) {}
          }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown category: baz'
        end
      end
    end

    describe "#enable" do
      let(:target_category) do
        [:global, :register_block, :register, :bit_field].sample
      end

      let(:category) { categories[target_category] }

      before do
        default_component_registration
        default_feature_definitions(target_category)
      end

      it "指定したカテゴリの#enableを呼び出して、定義したフィーチャーを有効にする" do
        expect(category).to receive(:enable).with(:fizz_0).and_call_original
        expect(category).to receive(:enable).with(match([:fizz_1, :fizz_2, :buzz])).and_call_original
        expect(category).to receive(:enable).with(:buzz, :buzz_0).and_call_original
        expect(category).to receive(:enable).with(:buzz, match([:buzz_1, :buzz_2])).and_call_original

        builder.enable(target_category, :fizz_0)
        builder.enable(target_category, [:fizz_1, :fizz_2, :buzz])
        builder.enable(target_category, :buzz, :buzz_0)
        builder.enable(target_category, :buzz, [:buzz_1, :buzz_2])
      end

      context "未定義のカテゴリを指定した場合" do
        it "BuilderErrorを起こす" do
          expect {
            builder.enable(:foo, :bar)
          }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown category: foo'

          expect {
            builder.enable(:bar, :baz, :qux)
          }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown category: bar'
        end
      end
    end

    describe "#build_factory" do
      before do
        default_component_registration
      end

      it "指定したコンポーネントのファクトリを生成する" do
        [:configuration, :register_map].shuffle.each do |component|
          factory = nil
          allow(component_registries[component]).to receive(:build_factory).and_wrap_original do |m|
            m.call.tap { |f| factory = f }
          end

          expect(builder.build_factory(:input, component)).to be factory
        end

        [:foo, :bar, :baz].shuffle.each do |component|
          factory = nil
          allow(component_registries[component]).to receive(:build_factory).and_wrap_original do |m|
            m.call.tap { |f| factory = f }
          end

          expect(builder.build_factory(:output, component)).to be factory
        end
      end

      context "未定義のコンポーネントが指定された場合" do
        it "BuilderErrorを起こす" do
          expect {
            builder.build_factory(:input, :foo)
          }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown component: foo'

          expect {
            builder.build_factory(:output, :register_map)
          }.to raise_rggen_error RgGen::Core::BuilderError, 'unknown component: register_map'
        end
      end
    end

    describe '#build_factories' do
      before do
        default_component_registration
      end

      it '指定した種類のコンポーネントファクトリを生成する' do
        factories = []
        [:configuration, :register_map, :foo, :bar, :baz].each do |component|
          allow(component_registries[component]).to receive(:build_factory).and_wrap_original do |m|
            m.call.tap { |f| factories << f }
          end
        end

        expect(builder.build_factories(:input, [])).to match([equal(factories[0]), equal(factories[1])])
        expect(builder.build_factories(:output, [])).to match([equal(factories[2]), equal(factories[3]), equal(factories[4])])
      end

      context '除外指定がある場合' do
        let(:exceptions) do
          [:foo, :bar, :baz].sample([1, 2, 3].sample)
        end

        it '除外していされていないコンポーネントのファクトリを生成する' do
          [:foo, :bar, :baz].each do |component|
            if exceptions.include?(component)
              expect(component_registries[component]).not_to receive(:build_factory)
            else
              expect(component_registries[component]).to receive(:build_factory).and_call_original
            end
          end

          builder.build_factories(:output, [*exceptions, :qux, :fizz])
        end
      end
    end

    describe  "#register_input_components" do
      let(:configuration_file_format) do
       [:yaml, :json, :ruby].sample
      end

      let(:configuration_file) do
        {
          yaml: 'configuration.yaml', json: 'configuration.json', ruby: 'configuration.rb'
        }[configuration_file_format]
      end

      let(:configuration_file_contents) do
        {
          yaml: 'prefix: foo',
          json: '{"prefix": "foo"}',
          ruby: 'prefix \'foo\''
        }[configuration_file_format]
      end

      let(:register_map_file_format) do
        [:yaml, :json, :ruby].sample
      end

      let(:register_map_file) do
        {
          yaml: 'register_map.yaml',
          json: 'register_map.json',
          ruby: 'register_map.rb'
        }[register_map_file_format]
      end

      let(:register_map_file_yaml_contents) do
        <<~REGISTER_MAP
          register_blocks:
          - name: register_block_0
            registers:
            - name: register_0
              bit_fields:
              - name: bit_field_0
        REGISTER_MAP
      end

      let(:register_map_file_json_contents) do
        <<~'REGISTER_MAP'
          {
            "register_blocks": [
              {
                "name": "register_block_0",
                "registers": [
                  {
                    "name": "register_0",
                    "bit_fields": [
                      {
                        "name": "bit_field_0"
                      }
                    ]
                  }
                ]
              }
            ]
          }
        REGISTER_MAP
      end

      let(:register_map_file_ruby_contents) do
        <<~REGISTER_MAP
          register_block {
            name 'register_block_0'
            register {
              name 'register_0'
              bit_field {
                name 'bit_field_0'
              }
            }
          }
        REGISTER_MAP
      end

      let(:register_map_file_contents) do
        {
          yaml: register_map_file_yaml_contents,
          json: register_map_file_json_contents,
          ruby: register_map_file_ruby_contents
        }[register_map_file_format]
      end

      it "Configuration／RegisterMapコンポーネントが登録される" do
        builder.register_input_components

        builder.define_simple_feature(:global, :prefix) do
          configuration do
            property :prefix
            build { |value| @prefix = value }
          end
        end
        builder.enable(:global, :prefix)

        [:register_block, :register, :bit_field].each do |category|
          builder.define_simple_feature(category, :name) do
            register_map do
              property :name
              build { |value| @name = "#{configuration.prefix}_#{value}" }
            end
          end
          builder.enable(category, :name)
        end

        allow(File).to receive(:readable?).with(configuration_file).and_return(true)
        allow(File).to receive(:binread).with(configuration_file).and_return(configuration_file_contents)
        factory = builder.build_factory(:input, :configuration)
        configuration = factory.create([configuration_file])

        allow(File).to receive(:readable?).with(register_map_file).and_return(true)
        allow(File).to receive(:binread).with(register_map_file).and_return(register_map_file_contents)
        factory = builder.build_factory(:input, :register_map)
        register_map = factory.create(configuration, [register_map_file])

        expect(configuration.prefix).to eq 'foo'
        expect(register_map.register_blocks.first.name).to eq 'foo_register_block_0'
        expect(register_map.registers.first.name).to eq 'foo_register_0'
        expect(register_map.bit_fields.first.name).to eq 'foo_bit_field_0'
      end
    end
  end
end
