module RgGen
  module Core
    module Base
      module InternalStruct
        module ClassMethods
          private

          def internal_structs
            @internal_structs ||= {}
          end

          def define_struct(struct_name, members, &body)
            internal_structs[struct_name] = Struct.new(*members, &body)
            define_method(struct_name) { __internal_structs[struct_name] }
            private(struct_name)
          end

          def inherited(subclass)
            super
            subclass.instance_variable_set(
              :@internal_structs, Hash[internal_structs]
            ) if instance_variable_defined?(:@internal_structs)
          end
        end

        def self.included(klass)
          klass.extend(ClassMethods)
        end

        private

        def __internal_structs
          self.class.__send__(:internal_structs)
        end
      end
    end
  end
end
