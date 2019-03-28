# frozen_string_literal: true

module RgGen
  module Core
    module OutputBase
      class CodeGenerator
        def register(kind, block)
          return unless block
          code_blocks[kind] << block
        end

        def generate(context, kind, code)
          return code unless generatable?(kind)
          execute_code_blocks(
            context, kind, code || context.create_blank_code
          )
        end

        def copy
          generator = CodeGenerator.new
          generator.copy_code_blocks(@code_blocks) if @code_blocks
          generator
        end

        private

        def code_blocks
          @code_blocks ||= Hash.new { |blocks, kind| blocks[kind] = [] }
        end

        def generatable?(kind)
          @code_blocks&.key?(kind)
        end

        def execute_code_blocks(context, kind, code)
          code_blocks[kind].each(&code_block_executor(context, code))
          code
        end

        def code_block_executor(context, code)
          lambda do |block|
            if block.arity.zero?
              code << context.instance_exec(&block)
            else
              context.instance_exec(code, &block)
            end
          end
        end

        protected

        def copy_code_blocks(original_blocks)
          original_blocks
            .each { |kind, blocks| code_blocks[kind] = blocks.dup }
        end
      end
    end
  end
end
