# frozen_string_literal: true

module RgGen
  module Core
    module Configuration
      class JSONLoader < Loader
        include HashLoader

        support_types [:json]

        def read_file(file)
          JSON.parse(File.binread(file), symbolize_names: true)
        end
      end
    end
  end
end
