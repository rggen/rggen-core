module RgGen
  module Core
    module InputBase
      class ComponentFactory < Base::ComponentFactory
        class << self
          attr_setter :input_data
        end

        attr_setter :loaders

        private

        def preprocess(args)
          return args unless root_factory?
          [*args.thru(-2), load_files(args.last)]
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
          loaders.find { |loader| loader.support?(file) } || (
            raise Core::LoadError.new('unsupported file type', file)
          )
        end

        def create_input_data(&block)
          self.class.input_data.new(valid_value_lists, &block)
        end

        def create_items(component, *sources)
          create_active_items(component, sources.last)
          create_passive_items(component)
        end

        def create_active_items(component, input_data)
          active_item_factories.each do |item_name, factory|
            create_item(component, factory, input_data[item_name])
          end
        end

        def create_passive_items(component)
          passive_item_factories.each_value do |factory|
            create_item(component, factory)
          end
        end

        def create_children(component, *sources)
          sources.last.children.each do |child_data|
            create_child(component, *sources.thru(-2), child_data)
          end
        end

        def finalize(component)
          component.validate
        end

        def active_item_factories
          @active_item_factories ||= Hash[
            *@item_factories.select { |_, f| f.active_item_factory? }.flatten
          ]
        end

        def passive_item_factories
          @passive_item_factories ||= Hash[
            *@item_factories.select { |_, f| f.passive_item_factory? }.flatten
          ]
        end

        protected

        def valid_value_lists
          [active_item_factories.keys].tap do |list|
            list.concat(child_factory.valid_value_lists) if child_factory
          end
        end
      end
    end
  end
end
