# frozen_string_literal: true

module RgGen
  module Core
    module Utility
      module CodeUtility
        class SourceFile
          include CodeUtility

          class << self
            attr_setter :ifndef_keyword
            attr_setter :endif_keyword
            attr_setter :define_keyword
            attr_setter :include_keyword
          end

          def initialize(file_path, &block)
            @file_path = file_path
            block_given? && Docile.dsl_eval(self, &block)
          end

          attr_reader :file_path

          def file_header(&block)
            @file_header = block
          end

          def include_guard(&block)
            @guard_macro = CodeBlock.new do |macro|
              execute_code_block(macro, block || default_include_guard, false)
            end
          end

          def default_guard_macro
            File.basename(file_path).upcase.gsub(/\W/, '_')
          end

          def include_file(file)
            @include_files ||= []
            @include_files << file
          end

          def body(&block)
            @bodies ||= []
            @bodies << block
          end

          def to_code
            CodeBlock.new do |code|
              code_blocks.each { |block| execute_code_block(code, block, true) }
            end
          end

          private

          def code_blocks
            [
              @file_header,
              include_guard_header,
              include_file_block,
              *Array(@bodies),
              include_guard_footer
            ].compact
          end

          def execute_code_block(code, code_block, insert_newline)
            if code_block.arity.zero?
              code << Docile.dsl_eval_with_block_return(self, &code_block)
            else
              Docile.dsl_eval(self, code, &code_block)
            end
            code << nl if insert_newline && !code.last_line_empty?
          end

          def default_include_guard
            -> { default_guard_macro }
          end

          def include_guard_header
            @guard_macro && lambda do
              [self.class.ifndef_keyword, self.class.define_keyword]
                .flat_map { |keyword| [keyword, space, @guard_macro, nl] }
            end
          end

          def include_file_block
            @include_files && lambda do
              keyword = self.class.include_keyword
              @include_files
                .flat_map { |file| [keyword, space, string(file), nl] }
            end
          end

          def include_guard_footer
            @guard_macro && (-> { self.class.endif_keyword })
          end
        end
      end
    end
  end
end
