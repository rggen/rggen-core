# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::Builder
  describe InputComponentRegistry do
    describe "ローダーの定義/登録" do
      def setup_file_access(file_name, load_data)
        allow(File).to receive(:readable?).with(file_name).and_return(true)
        allow(File).to receive(:binread).with(file_name).and_return(load_data)
      end

      let(:builder) do
        klass = Class.new do
          attr_reader :feature_registres
          def add_feature_registry(_registry_name, _category, feature_registry)
            @feature_registres ||= []
            @feature_registres << feature_registry
          end
        end
        klass.new
      end

      let(:registry) do
        InputComponentRegistry.new(:registry, builder)
      end

      before do
        registry.register_component do
          component(RgGen::Core::Configuration::Component)
          component_factory(RgGen::Core::Configuration::ComponentFactory)
          base_feature(RgGen::Core::Configuration::Feature)
          feature_factory(RgGen::Core::Configuration::FeatureFactory)
        end

        registry.base_loader(RgGen::Core::Configuration::Loader)

        builder.feature_registres[0].define_simple_feature(:foo) do
          property :foo
          build { |v| @foo = v.to_i }
        end

        builder.feature_registres[0].enable(:foo)
      end

      specify "#register_loaderで登録したローダー、#define_loaderで定義したローダーを使うことができる" do
        registry.register_loader(RgGen::Core::Configuration::YAMLLoader)
        registry.register_loader(RgGen::Core::Configuration::JSONLoader)
        registry.define_loader do
          include RgGen::Core::Configuration::HashLoader
          support_types [:txt]
          def read_file(file)
            Marshal.load(File.binread(file))
          end
        end

        value = rand(99)
        setup_file_access('test.yaml', "foo: #{value}")
        component = registry.build_root_factory.create(['test.yaml'])
        expect(component.foo).to eq value

        value = rand(99)
        setup_file_access('test.json', "{\"foo\": #{value}}")
        component = registry.build_root_factory.create(['test.json'])
        expect(component.foo).to eq value

        value = rand(99)
        setup_file_access('test.txt', Marshal.dump({ foo: value }))
        component = registry.build_root_factory.create(['test.txt'])
        expect(component.foo).to eq value
      end
    end
  end
end
