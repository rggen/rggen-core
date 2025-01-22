# frozen_string_literal: true

module RgGen
  module Core
    module Base
      module FeatureVariable
        module IncludeMethods
          private

          def feaure_scala_variable_get(name)
            self.class.feaure_scala_variable_get(name)
          end

          def feature_array_variable_get(name)
            self.class.feature_array_variable_get(name)
          end

          def feature_hash_variable_get(name)
            self.class.feature_hash_variable_get(name)
          end

          def feature_hash_array_variable_get(name)
            self.class.feature_hash_array_variable_get(name)
          end
        end

        def self.extended(klass)
          klass.include(IncludeMethods)
        end

        def feaure_scala_variable_get(name)
          if instance_variable_defined?(name)
            instance_variable_get(name)
          else
            parent_feature_variable_get(__method__, name)
          end
        end

        def feature_array_variable_get(name)
          parent = parent_feature_variable_get(__method__, name)
          own = instance_variable_get(name)

          if [parent, own] in [Array, Array]
            [*parent, *own]
          else
            parent || own
          end
        end

        def feature_hash_variable_get(name)
          parent = parent_feature_variable_get(__method__, name)
          own = instance_variable_get(name)

          if [parent, own] in [Hash, Hash]
            parent.merge(own)
          else
            parent || own
          end
        end

        def feature_hash_array_variable_get(name)
          parent = parent_feature_variable_get(__method__, name)
          own = instance_variable_get(name)

          if [parent, own] in [Hash, Hash]
            parent
              .merge(own) { |_, parent_val, own_val| [*parent_val, *own_val] }
          else
            parent || own
          end
        end

        private

        def feature_array_variable_push(name, value)
          array =
            instance_variable_get(name) ||
            instance_variable_set(name, [])
          array << value
        end

        def feature_hash_variable_store(name, key, value)
          hash =
            instance_variable_get(name) ||
            instance_variable_set(name, {})
          hash[key] = value
        end

        def feature_hash_array_variable_update(name, method, key, value)
          hash =
            instance_variable_get(name) ||
            instance_variable_set(name, Hash.new { |h, k| h[k] = [] })
          hash[key].__send__(method, value)
        end

        def feature_hash_array_variable_push(name, key, value)
          feature_hash_array_variable_update(name, :push, key, value)
        end

        def feature_hash_array_variable_prepend(name, key, value)
          feature_hash_array_variable_update(name, :prepend, key, value)
        end

        def parent_feature_variable_get(method, name)
          return unless superclass.respond_to?(method, true)

          superclass.__send__(method, name)
        end
      end
    end
  end
end
