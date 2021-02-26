# frozen_string_literal: true

module RgGen
  module Core
    module OutputBase
      class SourceFileComponentFactory < ComponentFactory
        private

        def create_component?(_, register_map)
          !register_map.document_only?
        end
      end
    end
  end
end
