# frozen_string_literal: true

module RgGen
  module Core
    module Utility
      module CodeUtility
        MacroDefiniion = Struct.new(:name, :value)

        class SourceFile
          include CodeUtility

          class << self
            attr_setter :ifndef_keyword
            attr_setter :endif_keyword
            attr_setter :define_keyword
            attr_setter :include_keyword
          end

          def initialize(file_path)
            @file_path = file_path
            block_given? && yield(self)
          end

          attr_reader :file_path

          def header(&block)
            @file_header = -> { block.call(@file_path) }
          end

          def include_guard
            @guard_macro =
              if block_given?
                yield(default_guard_macro)
              else
                default_guard_macro
              end
          end

          def include_files(files)
            @include_files ||= []
            @include_files.concat(Array(files))
          end

          def include_file(file)
            include_files([file])
          end

          def macro_definitions(macros)
            @macro_definitions ||= []
            @macro_definitions.concat(Array(macros))
          end

          def macro_definition(macro)
            macro_definitions([macro])
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

          def to_s
            to_code.to_s
          end

          private

          def code_blocks
            [
              @file_header,
              include_guard_header,
              include_file_block,
              macro_definition_block,
              *Array(@bodies),
              include_guard_footer
            ].compact
          end

          def execute_code_block(code, code_block, insert_newline)
            code.eval_block(&code_block)
            code << nl if insert_newline && !code.last_line_empty?
          end

          def default_guard_macro
            File.basename(file_path).upcase.gsub(/\W/, '_')
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

          def macro_definition_block
            @macro_definitions && lambda do
              keyword = self.class.define_keyword
              @macro_definitions.flat_map do |macro|
                if macro.value.nil?
                  [keyword, space, macro.name, nl]
                else
                  [keyword, space, macro.name, space, macro.value, nl]
                end
              end
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
