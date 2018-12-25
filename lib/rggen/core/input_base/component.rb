module RgGen
  module Core
    module InputBase
      class Component < Base::Component
        def add_feature(feature)
          super
          define_field_methods(feature)
        end

        def fields
          @features.each_value.flat_map(&:fields)
        end

        def validate
          @features.each_value(&:validate)
          @children.each(&:validate)
        end

        private

        def define_field_methods(feature)
          target = "@features[:#{feature.name}]"
          def_delegators(target, *feature.fields)
        end
      end
    end
  end
end
