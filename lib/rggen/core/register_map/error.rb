module RgGen
  module Core
    module RegisterMap
      class RegisterMapError < InputBase::InputError
      end

      module RaiseError
        def error(message, position = nil)
          raise RegisterMapError.new(message, position || @position)
        end
      end
    end
  end
end
