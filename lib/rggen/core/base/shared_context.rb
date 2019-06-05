# frozen_string_literal: true

module RgGen
  module Core
    module Base
      module SharedContext
        def attach_context(context)
          if is_a?(Module)
            define_method(:shared_context) { context }
          else
            instance_variable_set(:@shared_context, context)
            singleton_exec { attr_reader :shared_context }
          end
        end
      end
    end
  end
end
