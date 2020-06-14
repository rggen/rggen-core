# frozen_string_literal: true

module RgGen
  module Core
    module OutputBase
      class Component < Base::Component
        include Base::ComponentLayerExtension

        attr_reader :configuration
        attr_reader :register_map

        def post_initialize(configuration, register_map)
          @configuration = configuration
          @register_map = register_map
          @need_children = register_map.need_children?
          define_layer_methods
          define_proxy_calls(@register_map, @register_map.properties)
        end

        def children?
          !register_map.children.empty?
        end

        def add_feature(feature)
          super
          import_feature_methods(feature, :class)
        end

        def printables
          register_map.printables
        end

        def pre_build
          @features.each_value(&:pre_build)
        end

        def build
          @features.each_value(&method(:build_feature))
          @children.each(&:build)
        end

        def generate_code(code, kind, mode, target_or_range = nil, depth = 0)
          code_generator_contexts(kind, mode, target_or_range, depth)
            .each { |context| context.generate(code) }
        end

        def write_file(directory = nil)
          @features.each_value { |feature| feature.write_file(directory) }
          @children.each { |component| component.write_file(directory) }
        end

        private

        def build_feature(feature)
          feature.build
          import_feature_methods(feature, :object)
        end

        def import_feature_methods(feature, scope)
          methods = feature.exported_methods(scope)
          define_proxy_calls(feature, methods)
        end

        CodeGeneratorContext = Struct.new(:receivers, :args) do
          def generate(code)
            receivers.each { |receiver| receiver.generate_code(code, *args) }
          end
        end

        def code_generator_contexts(kind, mode, target_or_range, depth)
          [
            feature_code_generator_context(:pre_code, kind, target_or_range, depth),
            *main_code_generator_contexts(kind, mode, target_or_range, depth),
            feature_code_generator_context(:post_code, kind, target_or_range, depth)
          ].compact
        end

        def feature_code_generator_context(phase, kind, target_or_range, depth)
          (target_depth?(depth, target_or_range) || nil) &&
            CodeGeneratorContext.new(@features.each_value, [phase, kind])
        end

        def target_depth?(depth, target_or_range)
          if target_or_range.nil?
            true
          elsif target_or_range.respond_to?(:include?)
            target_or_range.include?(depth)
          else
            depth == target_or_range
          end
        end

        def main_code_generator_contexts(kind, mode, target_or_range, depth)
          [
            feature_code_generator_context(:main_code, kind, target_or_range, depth),
            CodeGeneratorContext.new(@children, [kind, mode, target_or_range, depth + 1])
          ].tap { |contexts| mode == :bottom_up && contexts.reverse! }
        end
      end
    end
  end
end
