# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class JSONLoader < Loader
        include HashLoader
        include InputBase::JSONLoader

        support_types [:json]

        def read_file(file)
          load_json(file)
        end
      end
    end
  end
end
