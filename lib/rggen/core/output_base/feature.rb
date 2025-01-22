# frozen_string_literal: true

module RgGen
  module Core
    module OutputBase
      class Feature < Base::Feature
        include Base::FeatureLayerExtension
        include CodeGeneratable
        include RaiseError

        class << self
          def exported_methods
            feature_array_variable_get(:@exported_methods)
          end

          private

          def pre_build(&body)
            feature_array_variable_push(:@pre_builders, body)
          end

          def build(&body)
            feature_array_variable_push(:@builders, body)
          end

          def write_file(file_name_pattern, &)
            @file_writer = FileWriter.new(file_name_pattern, &)
          end

          def export(*methods)
            methods.each do |method|
              exported_methods&.include?(method) ||
                feature_array_variable_push(:@exported_methods, method)
            end
          end
        end

        def post_initialize
          define_layer_methods
        end

        def pre_build
          feature_array_variable_get(:@pre_builders)
            &.each { |body| instance_exec(&body) }
        end

        def build
          feature_array_variable_get(:@builders)
            &.each { |body| instance_exec(&body) }
        end

        def export(*methods)
          methods.each do |method|
            unless exported_methods(:class)&.include?(method) ||
                   exported_methods(:object)&.include?(method)
              (@exported_methods ||= []) << method
            end
          end
        end

        def exported_methods(scope)
          if scope == :class
            self.class.exported_methods
          else
            @exported_methods
          end
        end

        def write_file(directory = nil)
          feaure_scala_variable_get(:@file_writer)
            &.write_file(self, directory)
        end

        private

        def configuration
          component.configuration
        end
      end
    end
  end
end
