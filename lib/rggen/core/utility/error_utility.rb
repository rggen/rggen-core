# frozen_string_literal: true

module RgGen
  module Core
    module Utility
      module ErrorUtility
        module_function

        def compose_error_message(error, verbose)
          lines = []
          lines << "[#{error.class.lastname}] #{error.message}"
          verbose &&
            error.backtrace.each { |trace| lines << "    #{trace}" }
          lines.join("\n")
        end
      end
    end
  end
end
