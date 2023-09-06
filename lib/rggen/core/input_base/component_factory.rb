# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class ComponentFactory < Base::ComponentFactory
        class << self
          def enable_no_children_error
            @enable_no_children_error = true
          end

          def disable_no_children_error
            @enable_no_children_error = false
          end

          def enable_no_children_error?
            @enable_no_children_error.nil? || @enable_no_children_error
          end
        end

        attr_setter :loaders

        private

        def preprocess(args)
          if root_factory?
            [*args[0..-2], load_files(args)]
          else
            args
          end
        end

        def load_files(args)
          files = args.last
          create_input_data(*args[0..-2]) do |input_data|
            files.each { |file| load_file(file, input_data) }
          end
        end

        def load_file(file, input_data)
          find_loader(file).load_file(file, input_data, valid_value_lists)
        end

        def find_loader(file)
          loaders.find { |l| l.support?(file) } ||
            (raise Core::LoadError.new('unsupported file type', file))
        end

        def valid_value_lists
          component_factories
            .transform_values(&->(f) { f.valid_value_list })
        end

        def create_input_data(*_args, &block)
        end

        def create_features(component, *sources)
          create_active_features(component, sources.last)
          create_passive_features(component)
        end

        def create_active_features(component, input_data)
          active_feature_factories.each do |name, factory|
            create_feature(component, factory, input_data[name])
          end
        end

        def create_passive_features(component)
          passive_feature_factories.each_value do |factory|
            create_feature(component, factory)
          end
        end

        def create_children(component, *sources)
          sources.last.children.each do |child_data|
            create_child(component, *sources[0..-2], child_data)
          end
        end

        def post_build(component)
          exist_no_children?(component) &&
            raise_no_children_error(component)
          component.post_build
          component.verify(:component)
        end

        def exist_no_children?(component)
          enable_no_children_error? &&
            component.need_children? && component.children.empty?
        end

        def enable_no_children_error?
          self.class.enable_no_children_error?
        end

        def raise_no_children_error(_component)
        end

        def finalize(component)
          component.verify(:all)
        end

        def active_feature_factories
          @active_feature_factories ||=
            @feature_factories&.select { |_, f| f.active_feature_factory? }
        end

        def passive_feature_factories
          @passive_feature_factories ||=
            @feature_factories&.select { |_, f| f.passive_feature_factory? }
        end

        protected

        def valid_value_list
          Array(active_feature_factories&.keys)
        end
      end
    end
  end
end
