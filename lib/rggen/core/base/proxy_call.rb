# frozen_string_literal: true

module RgGen
  module Core
    module Base
      class ProxyCall
        def initialize(receiver, method)
          @receiver = receiver
          @method = method
        end

        def call(*args, &block)
          @receiver.__send__(@method, *args, &block)
        end
      end
    end
  end
end
