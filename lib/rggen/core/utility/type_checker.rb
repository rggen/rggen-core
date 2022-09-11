# frozen_string_literal: true

module RgGen
  module Core
    module Utility
      module TypeChecker
        [String, Symbol, Integer, Array, Hash].each do |klass|
          module_eval(<<~DEFINE_METHOD, __FILE__, __LINE__ + 1)
            # module_function def string?(value)
            #   return value.match_class?(String) if value.respond_to?(:match_class?)
            #   value.is_a?(String)
            # end
            module_function def #{klass.to_s.downcase}?(value)
              return value.match_class?(#{klass}) if value.respond_to?(:match_class?)
              value.is_a?(#{klass})
            end
          DEFINE_METHOD
        end
      end
    end
  end
end
