# frozen_string_literal: true

module RgGen
  module Core
    module Base
      module InternalStruct
        def self.included(klass)
          klass.extend(self)
        end

        private

        def define_struct(name, members, &body)
          struct = Struct.new(*members, &body)
          define_private_method(name) { struct }
        end
      end
    end
  end
end
