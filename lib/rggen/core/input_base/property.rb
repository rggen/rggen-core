# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class Property
        def self.define(feature, name, **options, &)
          new(name, options, &).define(feature)
        end

        def initialize(name, options, &)
          @name = name
          @options = options
          @costom_property =
            if options[:body]
              create_costom_property(&options[:body])
            elsif block_given?
              create_costom_property(&)
            end
        end

        attr_reader :name

        def define(feature)
          feature.class_exec(self) do |property|
            define_method(property.name) do |*args, **kwargs, &block|
              property.evaluate(self, *args, **kwargs, &block)
            end
          end
        end

        def evaluate(feature, ...)
          feature.verify(@options[:verify]) if @options.key?(:verify)
          if proxy_property?
            proxy_property(feature, ...)
          else
            default_property(feature)
          end
        end

        private

        def create_costom_property(&body)
          body && Module.new.module_eval do
            define_method(:__costom_property__, &body)
            instance_method(:__costom_property__)
          end
        end

        def proxy_property?
          [
            @costom_property,
            @options[:forward_to_helper],
            @options[:forward_to]
          ].any?
        end

        def proxy_property(feature, ...)
          receiver, method =
            if @costom_property
              [@costom_property.bind(feature), :call]
            elsif @options[:forward_to_helper]
              [feature.class, @name]
            else
              [feature, @options[:forward_to]]
            end
          receiver.__send__(method, ...)
        end

        def default_property(feature)
          varible_name = "@#{@name.to_s.delete_suffix('?')}"
          if feature.instance_variable_defined?(varible_name)
            feature.instance_variable_get(varible_name)
          elsif @options.key?(:initial)
            set_initial_value(feature, varible_name)
          else
            evaluate_default_initial_value(feature, @options[:default])
          end
        end

        def set_initial_value(feature, varible_name)
          @options[:initial]
            .then { |v| evaluate_default_initial_value(feature, v) }
            .then { |v| feature.instance_variable_set(varible_name, v) }
        end

        def evaluate_default_initial_value(feature, value)
          value.is_a?(Proc) ? feature.instance_exec(&value) : value
        end
      end
    end
  end
end
