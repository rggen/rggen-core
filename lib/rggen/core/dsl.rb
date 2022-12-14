# frozen_string_literal: true

module RgGen
  module Core
    module DSL
      extend Forwardable

      attr_setter :builder

      [
        :input_component_registry,
        :output_component_registry,
        :register_loader,
        :setup_loader,
        :load_plugin,
        :define_loader,
        :define_feature,
        :define_simple_feature,
        :define_list_feature,
        :define_list_item_feature,
        :define_value_extractor,
        :enable,
        :enable_all,
        :delete,
        :setup_plugin
      ].each do |method_name|
        def_delegator :'RgGen.builder', method_name
      end
    end
  end

  extend Core::DSL
end
