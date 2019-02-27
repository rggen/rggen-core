# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class RubyLoader < Loader
        support_types [:rb]

        def read_file(file)
          input_data.load_file(file)
        end
      end
    end
  end
end
