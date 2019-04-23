# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class ComponentFactory < Base::ComponentFactory
        attr_setter :loaders

        private

        def preprocess(args)
          if root_factory?
            [*args[0..-2], load_files(args.last)]
          else
            args
          end
        end

        def load_files(files)
          create_input_data do |input_data|
            files.each { |file| load_file(file, input_data) }
          end
        end

        def load_file(file, input_data)
          find_loader(file).load_file(file, input_data, valid_value_lists)
        end

        def find_loader(file)
          loader = loaders.find { |l| l.support?(file) }
          loader || (raise Core::LoadError.new('unsupported file type', file))
        end

        def create_input_data(&block)
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

        def finalize(component)
          component.verify
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

        def valid_value_lists
          list = [Array(active_feature_factories&.keys)]
          list.concat(Array(child_factory&.valid_value_lists))
          list
        end
      end
    end
  end
end
