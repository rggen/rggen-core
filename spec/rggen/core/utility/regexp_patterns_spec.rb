# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::Utility
  describe RegexpPatterns do
    let(:utility) do
      Class.new { include(RegexpPatterns) }.new
    end

    describe '#variable_name' do
      it '識別子名にマッチするす' do
        [
          /[a-z_]\w*/i,
          /\s+[a-z_]\w*\s+/i,
          /\W+\s+[a-z_]\w*/i,
          /[a-z_]\w*\s+\W+/i
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).to match(utility.send(:variable_name))
        end

        [
          /\d\w+/,
          /\s+\d\w+/,
          /[a-z_]\w*[[:punct:]]+\w*/i,
          /\s+[a-z_]\w*[[:punct:]]+\w*\s+/i
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).not_to match(utility.send(:variable_name))
        end
      end
    end

    describe '#integer' do
      it '2進数表記にマッチする' do
        [
          /0b[01]/i,
          /0b[01]+/i,
          /\+0b[01]+/i,
          /\-0b[01]+/i,
          /0b[01]+_[01]+/i,
          /\s+[+-]?0b[01]+/i,
          /\w\s+[+-]?0b[01]+/i,
          /0b[01]+\s+/i,
          /0b[01]+\s+\w/i
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).to match(utility.send(:integer))
        end

        [
          /0b[01]+[2-9]+[01]+/i,
          /0b[01]+[[:alpha:]][01]+/i,
          /\w0b[01]+/i,
          /0b[01]+[[:alpha:]]/i,
          /[+-]{2}0b[01]/i,
          /0b_[01]+/i,
          /0b[01]+_{2,}[01]+/i,
          /0b[01]+_/i
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).not_to match(utility.send(:integer))
        end
      end

      it '10進数表記にマッチする' do
        [
          /0/,
          /[1-9]/,
          /[1-9][0-9]+/,
          /\+[1-9][0-9]*/,
          /\-[1-9][0-9]*/,
          /[1-9][0-9]+_[0-9]+/,
          /\s+[+-]?[1-9][0-9]*/i,
          /\w\s+[+-]?[1-9][0-9]*/i,
          /[1-9][0-9]*\s+/i,
          /[1-9][0-9]*\s+\w/i
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).to match(utility.send(:integer))
        end

        [
          /0[0-9]/,
          /[[:alpha:]][1-9][0-9]*/,
          /[1-9][0-9]*[[:alpha:]][0-9]+/,
          /[1-9][0-9]*[[:alpha:]]/,
          /[+-]{2}[1-9][0-9]*/,
          /_[1-9][0-9]*/,
          /[1-9][0-9]*_{2,}[0-9]+/,
          /[1-9][0-9]*_/
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).not_to match(utility.send(:integer))
        end
      end

      it '16進数表記にマッチする' do
        [
          /0x[0-9a-f]/i,
          /0x[0-9a-f]+/i,
          /\+0x[0-9a-f]+/i,
          /\-0x[0-9a-f]+/i,
          /0x[0-9a-f]+_[0-9a-f]+/i,
          /\s+[+-]?0x[0-9a-f]+/i,
          /\w\s+[+-]?0x[0-9a-f]+/i,
          /0x[0-9a-f]+\s+/i,
          /0x[0-9a-f]+\s+\w/i
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).to match(utility.send(:integer))
        end

        [
          /0x[0-9a-f]+[g-z]+[0-9a-f]+/i,
          /\w0x[0-9a-f]+/i,
          /0x[0-9a-f]+[g-z]/i,
          /[+-]{2}0x[0-9a-f]/i,
          /0x_[0-9a-f]+/i,
          /0x[0-9a-f]+_{2,}[0-9a-f]+/i,
          /0x[0-9a-f]+_/i
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).not_to match(utility.send(:integer))
        end
      end
    end
  end
end
