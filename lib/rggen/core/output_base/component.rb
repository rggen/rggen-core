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

        def generate_code(kind, mode, code = nil)
          code_generators(kind, mode).inject(code) { |c, g| g[c] }
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

        def code_generators(kind, mode)
          [
            [@features.each_value, [:pre_code, kind]],
            *main_code_contexts(kind, mode),
            [@features.each_value, [:post_code, kind]]
          ].map do |receivers, args|
            lambda do |code|
              receivers.inject(code) { |c, r| r.generate_code(*args, c) }
            end
          end
        end

        def main_code_contexts(kind, mode)
          contexts = [
            [@features.each_value, [:main_code, kind]],
            [@children, [kind, mode]]
          ]
          contexts.reverse! if mode == :bottom_up
          contexts
        end
      end
    end
  end
end
