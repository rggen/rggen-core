# frozen_string_literal: true

RSpec.describe RgGen::Core::Builder::InputComponentRegistry do
  describe 'ローダーの定義/登録' do
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
      described_class.new(:registry, builder)
    end

    before do
      registry.register_component do
        component(
          RgGen::Core::Configuration::Component,
          RgGen::Core::Configuration::ComponentFactory
        )
        feature(
          RgGen::Core::Configuration::Feature,
          RgGen::Core::Configuration::FeatureFactory
        )
      end

      builder.feature_registres[0].define_simple_feature(:foo) do
        property :foo
        build { |v| @foo = v.to_i }
      end

      builder.feature_registres[0].enable(:foo)
    end

    specify '#register_loader/#register_loadersで登録したローダーを使うことができる' do
      registry.register_loader(RgGen::Core::Configuration::RubyLoader)
      registry.register_loaders([
        RgGen::Core::Configuration::YAMLLoader,
        RgGen::Core::Configuration::JSONLoader
      ])

      value = rand(99)
      setup_file_access('test.rb', "foo #{value}")
      component = registry.build_factory.create(['test.rb'])
      expect(component.foo).to eq value

      value = rand(99)
      setup_file_access('test.yaml', "foo: #{value}")
      component = registry.build_factory.create(['test.yaml'])
      expect(component.foo).to eq value

      value = rand(99)
      setup_file_access('test.json', "{\"foo\": #{value}}")
      component = registry.build_factory.create(['test.json'])
      expect(component.foo).to eq value
    end
  end
end
