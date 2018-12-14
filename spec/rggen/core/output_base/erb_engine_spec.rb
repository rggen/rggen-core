require 'spec_helper'

module RgGen::Core::OutputBase
  describe ERBEngine do
    before(:all) do
      engine = ERBEngine.instance
      if engine.instance_variable_defined?(:@templates)
        @templates_original = engine.instance_variable_get(:@templates)
        engine.remove_instance_variable(:@templates)
      end
    end

    after(:all) do
      if @templates_original
        engine = ERBEngine.instance
        engine.instance_variable_set(:@templates, @templates_original)
      end
    end

    let(:engine) { ERBEngine.instance }

    describe "#process_template" do
      let(:context) do
        Object.new.tap do |c|
          def c.foo; 'foo'; end
          def c.bar; 'bar'; end
          def c.baz; 'baz'; end
        end
      end

      it "ERB形式のテンプレートを処理する" do
        expect(File).to receive(:binread).with('foo.erb').and_return('<%= object_id %> <%= foo %>')
        expect(engine.process_template(context, 'foo.erb')).to eq "#{context.object_id} #{context.foo}"

        expect(File).to receive(:binread).with(File.ext(__FILE__, '.erb')).and_return('<%= object_id %> <%= bar %>')
        expect(engine.process_template(context)).to eq "#{context.object_id} #{context.bar}"

        caller_location = double('caller_location')
        allow(caller_location).to receive(:path).and_return('baz.rb')
        expect(File).to receive(:binread).with('baz.erb').and_return('<%= object_id %> <%= baz %>')
        expect(engine.process_template(context, nil, caller_location)).to eq "#{context.object_id} #{context.baz}"
      end
    end
  end
end
