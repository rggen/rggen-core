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
        end

        def add_feature(feature)
          super
          define_feature_method_accessor(feature)
        end

        def build
          @features.each_value(&:build)
          @children.each(&:build)
        end

        def generate_code(kind, mode, code = nil)
          code_generators(mode).inject(code) do |c, g|
            g.call(kind, mode, c)
          end
        end

        def write_file(directory = nil)
          @features.each_value { |feature| feature.write_file(directory) }
          @children.each { |component| component.write_file(directory) }
        end

        private

        def define_property_accessors
          def_delegators(:@source, *@source.properties)
        end

        def define_feature_method_accessor(feature)
          target = "@features[:#{feature.name}]"
          def_delegators(target, *feature.exported_methods)
        end

        def code_generators(mode)
          [
            feature_code_generator(:pre),
            *main_code_generators(mode),
            feature_code_generator(:post)
          ]
        end

        def main_code_generators(mode)
          case mode
          when :top_down
            [feature_code_generator(:main), child_component_code_generator]
          when :bottom_up
            [child_component_code_generator, feature_code_generator(:main)]
          end
        end

        def feature_code_generator(phase)
          lambda do |kind, _mode, code|
            @features.each_value.inject(code) do |c, feature|
              feature.generate_code(phase, kind, c)
            end
          end
        end

        def child_component_code_generator
          lambda do |kind, mode, code|
            @children.inject(code) do |c, component|
              component.generate_code(kind, mode, c)
            end
          end
        end
      end
    end
  end
end
