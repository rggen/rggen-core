# frozen_string_literal: true

module RgGen
  module Core
    module OutputBase
      module RaiseError
        def error(message)
          raise GeneratorError.new(message)
        end
      end
    end
  end
end
