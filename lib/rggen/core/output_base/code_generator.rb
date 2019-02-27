# frozen_string_literal: true

module RgGen
  module Core
    module OutputBase
      class CodeGenerator
        def register(kind, block)
          return unless block
          (@code_generators ||= {})[kind] = block
        end

        def generate(context, kind, code)
          return code unless @code_generators
          return code unless @code_generators.key?(kind)
          code ||= context.create_blank_code
          process_code_block(context, kind, code)
        end

        def copy
          generator = CodeGenerator.new
          generator.copy_code_generators(@code_generators)
          generator
        end

        private

        def process_code_block(context, kind, code)
          if @code_generators[kind].arity.zero?
            code << context.instance_exec(&@code_generators[kind])
          else
            context.instance_exec(code, &@code_generators[kind])
          end
          code
        end

        protected

        def copy_code_generators(code_generators)
          return unless code_generators
          @code_generators = Hash[code_generators]
        end
      end
    end
  end
end
