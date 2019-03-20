# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::Utility::CodeUtility
  describe StructureDefinition do
    include RgGen::Core::Utility::CodeUtility

    def structure_definition(&block)
      klass = Class.new(StructureDefinition) do
        if [true, false].sample
          def header_code; :foo_header; end
          def footer_code; :foo_footer; end
        else
          def header_code(code); code << :foo_header << nl; end
          def footer_code(code); code << :foo_footer << nl; end
        end
      end
      klass.new(&block).to_code
    end

    def structure_definition_with_pre_post(&block)
      klass = Class.new(StructureDefinition) do
        if [true, false].sample
          def header_code; :foo_header; end
          def footer_code; :foo_footer; end
          def pre_body_code; :foo_pre_body; end
          def post_body_code; :foo_post_body; end
        else
          def header_code(code); code << :foo_header << nl; end
          def footer_code(code); code << :foo_footer << nl; end
          def pre_body_code(code); code << :foo_pre_body << nl; end
          def post_body_code(code); code << :foo_post_body << nl; end
        end
      end
      klass.new(&block).to_code
    end

    it '構造の定義を行うコードを生成する' do
      expect(
        structure_definition do
          body { :foo_body }
        end
      ).to match_string(<<~'STRUCTURE')
        foo_header
          foo_body
        foo_footer
      STRUCTURE

      expect(
        structure_definition do
          body { "foo_body\n" }
        end
      ).to match_string(<<~'STRUCTURE')
        foo_header
          foo_body
        foo_footer
      STRUCTURE

      expect(
        structure_definition do
          body { |code| code << :foo_body }
        end
      ).to match_string(<<~'STRUCTURE')
        foo_header
          foo_body
        foo_footer
      STRUCTURE

      expect(
        structure_definition do
          body { |code| code << :foo_body << nl }
        end
      ).to match_string(<<~'STRUCTURE')
        foo_header
          foo_body
        foo_footer
      STRUCTURE

      expect(
        structure_definition do
          body { "foo_body_0\nfoo_body_1" }
          body { |code| code << :foo_body_2 << nl }
        end
      ).to match_string(<<~'STRUCTURE')
        foo_header
          foo_body_0
          foo_body_1
          foo_body_2
        foo_footer
      STRUCTURE

      expect(
        structure_definition_with_pre_post do
          body { :foo_body_0 }
          body { :foo_body_1 }
        end
      ).to match_string(<<~'STRUCTURE')
        foo_header
          foo_pre_body
          foo_body_0
          foo_body_1
          foo_post_body
        foo_footer
      STRUCTURE
    end
  end
end
