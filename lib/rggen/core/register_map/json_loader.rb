# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class JSONLoader < Loader
        include HashLoader

        support_types [:json]

        def read_file(file)
          JSON.parse(File.binread(file))
        end
      end
    end
  end
end
