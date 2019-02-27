# frozen_string_literal: true

module RgGen
  module Core
    module Base
      module SharedContext
        def self.included(klass)
          klass.extend(self)
        end

        def shared_context(context)
          define_private_method(:shared_context) { context }
        end
      end
    end
  end
end
