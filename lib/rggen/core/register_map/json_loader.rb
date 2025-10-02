# frozen_string_literal: true

module RgGen
  module Core
    module RegisterMap
      class JSONLoader < Loader
        include HashLoader
        include InputBase::JSONLoader

        support_types [:json]
      end
    end
  end
end
