require 'spec_helper'

module RgGen::Core::Base
  describe SharedContext do
    def define_class(context)
      klass = Class.new { include SharedContext }
      klass.shared_context(context)
      klass
    end

    it "オブジェクト間で共有するコンテキストオブジェクトを設定する" do
      shared_context = Object.new
      klass = define_class(shared_context)
      expect(klass.new.send(:shared_context)).to be shared_context
      expect(klass.new.send(:shared_context)).to be shared_context
    end

    specify "コンテキストオブジェクトは継承される" do
      shared_context = Object.new
      klass = Class.new(define_class(shared_context))
      expect(klass.new.send(:shared_context)).to be shared_context
    end

    context "継承先で共有コンテキストオブジェクトが再設定された場合" do
      specify "継承元の共有コンテキストオブジェクトは変更されない" do
        shared_objects = [Object.new, Object.new]
        class_0 = define_class(shared_objects[0])
        class_1 = Class.new(class_0) { shared_context shared_objects[1] }

        expect(class_0.new.send(:shared_context)).to be shared_objects[0]
        expect(class_1.new.send(:shared_context)).to be shared_objects[1]
      end
    end
  end
end
