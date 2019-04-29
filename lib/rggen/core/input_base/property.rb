# frozen_string_literal: true

module RgGen
  module Core
    module InputBase
      class Property
        def self.define(feature, name, **options, &body)
          new(name, options, body).define(feature)
        end

        def initialize(name, options, body)
          @name = name
          @options = options
          @costom_property = create_costom_property(@options[:body] || body)
        end

        attr_reader :name

        def define(feature)
          feature.class_exec(self) do |property|
            define_method(property.name) do |*args, &block|
              property.evaluate(self, args, block)
            end
          end
        end

        def evaluate(feature, args, block)
          feature.verify(@options[:verify]) if @options.key?(:verify)
          if proxy_property?
            proxy_property(feature, args, block)
          else
            default_property(feature)
          end
        end

        private

        def create_costom_property(body)
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

        def proxy_property(feature, args, block)
          receiver, method =
            if @costom_property
              [@costom_property.bind(feature), :call]
            elsif @options[:forward_to_helper]
              [feature.class, @name]
            else
              [feature, @options[:forward_to]]
            end
          receiver.__send__(method, *args, &block)
        end

        def default_property(feature)
          varible_name = "@#{@name[-1] == '?' ? @name[0..-2] : @name}"
          if feature.instance_variable_defined?(varible_name)
            feature.instance_variable_get(varible_name)
          else
            @options[:default]
          end
        end
      end
    end
  end
end
