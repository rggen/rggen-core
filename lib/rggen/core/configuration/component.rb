# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class Component < InputBase::Component
        private

        def post_initialize
          need_no_children
        end
      end
    end
  end
end
