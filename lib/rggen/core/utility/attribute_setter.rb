# frozen_string_literal: true

module RgGen
  module Core
    module Utility
      module AttributeSetter
        module Extension
          def attributes
            @attributes ||= []
          end

          private

          DEFAULT_VALUE = Object.new.freeze

          def define_attribute(name, default_value = nil)
            attributes << name.to_sym
            variable_name = "@#{name}"
            define_method(name) do |value = DEFAULT_VALUE|
              if value.equal?(DEFAULT_VALUE)
                attribute_value_get(variable_name, default_value)
              else
                instance_variable_set(variable_name, value)
              end
            end
          end
        end

        def self.included(class_or_module)
          class_or_module.extend(Extension)
        end

        def apply_attributes(**attributes)
          attributes.each do |name, value|
            __send__(name, value) if self.class.attributes.include?(name)
          end
        end

        private

        def attribute_value_get(variable_name, default_value)
          if instance_variable_defined?(variable_name)
            instance_variable_get(variable_name)
          elsif default_value.is_a?(Proc)
            instance_exec(&default_value)
          else
            default_value
          end
        end
      end
    end
  end
end
