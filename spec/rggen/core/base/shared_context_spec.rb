# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::Base
  describe SharedContext do
    def define_class(context)
      klass = Class.new { extend SharedContext }
      klass.attach_context(context)
      klass
    end

    it "オブジェクト間で共有するコンテキストオブジェクトを設定する" do
      shared_context = Object.new
      klass = define_class(shared_context)
      expect(klass.new.shared_context).to be shared_context
      expect(klass.new.shared_context).to be shared_context
    end

    specify "コンテキストオブジェクトは継承される" do
      shared_context = Object.new
      klass = Class.new(define_class(shared_context))
      expect(klass.new.shared_context).to be shared_context
    end

    context "継承先で共有コンテキストオブジェクトが再設定された場合" do
      specify "継承元の共有コンテキストオブジェクトは変更されない" do
        shared_contexts = [Object.new, Object.new]
        class_0 = define_class(shared_contexts[0])
        class_1 = Class.new(class_0) { attach_context shared_contexts[1] }

        expect(class_0.new.shared_context).to be shared_contexts[0]
        expect(class_1.new.shared_context).to be shared_contexts[1]
      end
    end

    specify 'オブジェクトに対してもコンテキストオブジェクトを設定できる' do
      shared_context = Object.new
      object = Object.new.tap { |o| o.extend SharedContext }
      object.attach_context(shared_context)
      expect(object.shared_context).to be shared_context
    end
  end
end
