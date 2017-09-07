module RgGen
  module Core
    module Configuration
      class Item < InputBase::Item
        include RaiseError

        alias_method :configuration, :component
      end
    end
  end
end
