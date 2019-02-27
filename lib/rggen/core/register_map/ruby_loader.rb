# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class RubyLoader < Loader
        support_types [:rb]

        def read_file(file)
          register_map.load_file(file)
        end
      end
    end
  end
end
