# frozen_string_literal: true

module RgGen
  module Core
    module OutputBase
      class Component < Base::Component
        include Base::HierarchicalAccessors

        attr_reader :configuration
        attr_reader :source

        def post_initialize(_paren, configuration, source)
          @configuration = configuration
          @source = source
          @need_children = source.need_children?
          define_hierarchical_accessors
          define_property_accessors
          define_children_presense_indicator
        end

        def children?
          !source.children.empty?
        end

        def add_feature(feature)
          super
          import_feature_methods(feature, :class)
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

        def define_property_accessors
          def_delegators(:@source, *@source.properties)
        end

        INDICATOR_NAMES = {
          register_map: :register_blocks?,
          register_block: :registers?,
          register: :bit_fields?
        }.freeze

        def define_children_presense_indicator
          indicator_name = INDICATOR_NAMES[hierarchy]
          indicator_name &&
            singleton_exec { alias_method indicator_name, :children? }
        end

        def build_feature(feature)
          feature.build
          import_feature_methods(feature, :object)
        end

        def import_feature_methods(feature, scope)
          receiver = "@features[:#{feature.feature_name}]"
          methods = feature.exported_methods(scope)
          def_delegators(receiver, *methods)
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
