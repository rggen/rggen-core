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
      registry.register_global_component do
        component(
          RgGen::Core::Configuration::Component,
          RgGen::Core::Configuration::ComponentFactory
        )
        feature(
          RgGen::Core::Configuration::Feature,
          RgGen::Core::Configuration::FeatureFactory
        )
      end

      [:foo, :bar, :baz, :qux].each do |property_name|
        builder.feature_registres[0].define_simple_feature(property_name) do
          property property_name
          build { |v| instance_variable_set("@#{property_name}", v.to_i) }
        end
      end
    end

    specify '#register_loader/#register_loadersで登録したローダーを使うことができる' do
      registry.register_loader :ruby_based, RgGen::Core::Configuration::RubyLoader
      registry.register_loaders :hash_based, [RgGen::Core::Configuration::YAMLLoader, RgGen::Core::Configuration::JSONLoader]

      values = [rand(99), rand(99), rand(99), rand(99)]
      setup_file_access('test.rb', "foo #{values[0]}; bar #{values[1]}; baz #{values[2]}; qux #{values[3]}")
      component = registry.build_factory.create(['test.rb'])
      expect(component.foo).to eq values[0]
      expect(component.bar).to eq values[1]
      expect(component.baz).to eq values[2]
      expect(component.qux).to eq values[3]

      values = [rand(99), rand(99), rand(99), rand(99)]
      setup_file_access('test.yaml', "{foo: #{values[0]}, bar: #{values[1]}, baz: #{values[2]}, qux: #{values[3]}}")
      component = registry.build_factory.create(['test.yaml'])
      expect(component.foo).to eq values[0]
      expect(component.bar).to eq values[1]
      expect(component.baz).to eq values[2]
      expect(component.qux).to eq values[3]

      values = [rand(99), rand(99), rand(99), rand(99)]
      setup_file_access('test.json', "{\"foo\": #{values[0]}, \"bar\": #{values[1]}, \"baz\": #{values[2]}, \"qux\": #{values[3]}}")
      component = registry.build_factory.create(['test.json'])
      expect(component.foo).to eq values[0]
      expect(component.bar).to eq values[1]
      expect(component.baz).to eq values[2]
      expect(component.qux).to eq values[3]
    end

    describe '#setup_loader' do
      specify '#register_loader/#register_loadersで登録したローダーを使うことができる' do
        registry.setup_loader(:ruby_based) do |entry|
          entry.register_loader RgGen::Core::Configuration::RubyLoader
        end
        registry.setup_loader(:hash_based) do |entry|
          entry.register_loaders [RgGen::Core::Configuration::YAMLLoader, RgGen::Core::Configuration::JSONLoader]
        end

        values = [rand(99), rand(99), rand(99), rand(99)]
        setup_file_access('test.rb', "foo #{values[0]}; bar #{values[1]}; baz #{values[2]}; qux #{values[3]}")
        component = registry.build_factory.create(['test.rb'])
        expect(component.foo).to eq values[0]
        expect(component.bar).to eq values[1]
        expect(component.baz).to eq values[2]
        expect(component.qux).to eq values[3]

        values = [rand(99), rand(99), rand(99), rand(99)]
        setup_file_access('test.yaml', "{foo: #{values[0]}, bar: #{values[1]}, baz: #{values[2]}, qux: #{values[3]}}")
        component = registry.build_factory.create(['test.yaml'])
        expect(component.foo).to eq values[0]
        expect(component.bar).to eq values[1]
        expect(component.baz).to eq values[2]
        expect(component.qux).to eq values[3]

        values = [rand(99), rand(99), rand(99), rand(99)]
        setup_file_access('test.json', "{\"foo\": #{values[0]}, \"bar\": #{values[1]}, \"baz\": #{values[2]}, \"qux\": #{values[3]}}")
        component = registry.build_factory.create(['test.json'])
        expect(component.foo).to eq values[0]
        expect(component.bar).to eq values[1]
        expect(component.baz).to eq values[2]
        expect(component.qux).to eq values[3]
      end

      specify '#ignore_valueで無視する値を指定できる' do
        registry.setup_loader(:hash_based) do |entry|
          entry.register_loader RgGen::Core::Configuration::YAMLLoader
          entry.ignore_value :foo
          entry.ignore_value nil, :bar
          entry.ignore_value [nil], :baz
        end

        values = [rand(99), rand(99), rand(99), rand(99)]
        setup_file_access('test.yaml', "{foo: #{values[0]}, bar: #{values[1]}, baz: #{values[2]}, qux: #{values[3]}}")
        component = registry.build_factory.create(['test.yaml'])
        expect(component.foo).to be_nil
        expect(component.bar).to be_nil
        expect(component.baz).to be_nil
        expect(component.qux).to eq values[3]
      end

      specify '#ignore_valuesで無視する値を指定できる' do
        registry.setup_loader(:hash_based) do |entry|
          entry.register_loader RgGen::Core::Configuration::YAMLLoader
          entry.ignore_values [:foo]
          entry.ignore_values nil, [:bar]
          entry.ignore_values [nil], [:baz]
        end

        values = [rand(99), rand(99), rand(99), rand(99)]
        setup_file_access('test.yaml', "{foo: #{values[0]}, bar: #{values[1]}, baz: #{values[2]}, qux: #{values[3]}}")
        component = registry.build_factory.create(['test.yaml'])
        expect(component.foo).to be_nil
        expect(component.bar).to be_nil
        expect(component.baz).to be_nil
        expect(component.qux).to eq values[3]
      end
    end

    specify '#define_value_extractorで値の抽出を定義できる' do
      loader = Class.new(RgGen::Core::Configuration::Loader) do
        support_types [:yaml]
        def read_file(file)
          YAML.load(File.binread(file))
        end
      end

      registry.setup_loader(:hash_based) { |entry| entry.register_loader loader }
      registry.define_value_extractor(:hash_based, :foo) do
        extract { |data| data['foo'].to_i * 2 }
      end
      registry.define_value_extractor(:hash_based, nil, :bar) do
        extract { |data| data['bar'].to_i * 3 }
      end
      registry.define_value_extractor(:hash_based, [nil], :baz) do
        extract { |data| data['baz'].to_i * 4 }
      end

      values = [rand(99), rand(99), rand(99), rand(99)]
      setup_file_access('test.yaml', "{foo: #{values[0]}, bar: #{values[1]}, baz: #{values[2]}, qux: #{values[3]}}")
      component = registry.build_factory.create(['test.yaml'])
      expect(component.foo).to eq (values[0] * 2)
      expect(component.bar).to eq (values[1] * 3)
      expect(component.baz).to eq (values[2] * 4)
      expect(component.qux).to be_nil
    end
  end
end
