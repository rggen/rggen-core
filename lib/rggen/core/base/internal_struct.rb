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
          define_method(name) { struct }
          private name
        end
      end
    end
  end
end
