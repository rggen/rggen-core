module RgGen
  module Core
    module RegisterMap
      class Loader < InputBase::Loader
        private

        def register_map
          input_data
        end
      end
    end
  end
end
