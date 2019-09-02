# frozen_string_literal: true

module RgGen
  module Core
    module Base
      module InternalStruct
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
