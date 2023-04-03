# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class RegisterMapError < Core::RuntimeError
      end

      module RaiseError
        include InputBase::Error

        private

        def error_exception
          RegisterMapError
        end
      end
    end
  end
end
