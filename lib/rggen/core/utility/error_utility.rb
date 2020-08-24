# frozen_string_literal: true

module RgGen
  module Core
    module Utility
      module ErrorUtility
        class MessageComposer
          def compose(error, verbose, backtrace)
            lines = []
            add_basic_info(error, lines)
            add_verbose_info(error, lines) if verbose
            add_backtrace(error, lines) if backtrace
            lines.join("\n")
          end

          private

          def add_basic_info(error, lines)
            lines << "[#{error.class.lastname}] #{error}"
          end

          def add_verbose_info(error, lines)
            return unless error.respond_to?(:verbose_info)
            return unless error.verbose_info

            lines << 'verbose information:'
            error
              .verbose_info.lines(chomp: true)
              .each { |info| lines << "    #{info}" }
          end

          def add_backtrace(error, lines)
            lines << 'backtrace:'
            error.backtrace.each { |trace| lines << "    #{trace}" }
          end
        end

        module_function

        def compose_error_message(error, verbose, backtrace)
          MessageComposer.new.compose(error, verbose, backtrace)
        end
      end
    end
  end
end
