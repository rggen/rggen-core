# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::Utility
  describe RegexpPatterns do
    let(:utility) do
      Class.new { include(RegexpPatterns) }.new
    end

    def regexp_pattern(type)
      /\A#{utility.send(type)}\z/
    end

    describe '#variable_name' do
      it '識別子名にマッチするす' do
        [
          /_/i,
          /_+/i,
          /[a-z]/i,
          /[a-z]+/i,
          /_\d/i,
          /_\d+/i,
          /[a-z]\d/i,
          /[a-z]\d+/i,
          /[_a-z]\w+/i
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).to match(regexp_pattern(:variable_name))
        end

        [
          /\d/i,
          /\d+/i,
          /\d_/i,
          /\d_+/i,
          /\d[a-z]/i,
          /\d[a-z]+/i,
          /\d\w+/i
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).not_to match(regexp_pattern(:variable_name))
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
          /0b[01]+_[01]+/i
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).to match(regexp_pattern(:integer))
        end

        [
          /0b[2-9]/i,
          /0b[2-9][0-1]/i,
          /0b[0-1][2-9]/i,
          /0b[a-z]/i,
          /0b[a-z][0-1]/i,
          /0b[0-1][a-z]/i,
          /0b_[0-1]+/i,
          /0b_+[0-1]+/i
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).not_to match(regexp_pattern(:integer))
        end
      end

      it '10進数表記にマッチする' do
        [
          /0/,
          /[1-9]/,
          /[1-9][0-9]+/,
          /\+[1-9][0-9]*/,
          /\-[1-9][0-9]*/,
          /[1-9][0-9]+_[0-9]+/
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).to match(regexp_pattern(:integer))
        end

        [
          /0[0-9]/,
          /[a-z][1-9]/,
          /[1-9][a-z]/,
          /[1-9][0-9]+[a-z]/,
          /_[1-9]/,
          /_[+-][1-9]/,
          /_[1-9][0-9]+/i,
          /[1-9]__+[0-9]/i,
          /[1-9]_/i,
          /[1-9][0-9]_/i,
          /[a-z]\d/i,
          /\d[a-z]/i
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).not_to match(regexp_pattern(:integer))
        end
      end

      it '16進数表記にマッチする' do
        [
          /0x[0-9a-f]/i,
          /0x[0-9a-f]+/i,
          /\+0x[0-9a-f]+/i,
          /\-0x[0-9a-f]+/i,
          /0x[0-9a-f]_[0-9a-f]/i
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).to match(regexp_pattern(:integer))
        end

        [
          /0x[g-z]/i,
          /0x[g-z][0-9a-f]/i,
          /0x[0-9a-f][g-z]/i,
          /0x_[0-9a-f]/i,
          /0x[0-9a-f]_/i,
          /0x[0-9a-f]__+[0-9a-f]/i,
          /0x_[0-9a-f]/i,
          /[a-z]0x[0-9a-f]/i
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).not_to match(regexp_pattern(:integer))
        end
      end
    end

    describe '#truthy_pattern' do
      it 'true/on/yesにマッチする' do
        [
          /true/i, /on/i, /yes/i
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).to match(regexp_pattern(:truthy_pattern))
        end

        [
          /false/i, /off/i, /no/i, /foo/i, /\s*/i
        ].each do |pattern|
          string  = random_string(pattern)
          expect(string).not_to match(regexp_pattern(:truthy_pattern))
        end
      end
    end

    describe '#falsey_pattern' do
      it 'false/off/noにマッチする' do
        [
          /false/i, /off/i, /no/i
        ].each do |pattern|
          string = random_string(pattern)
          expect(string).to match(regexp_pattern(:falsey_pattern))
        end

        [
          /true/i, /on/i, /yes/i, /foo/i, /\s*/i
        ].each do |pattern|
          string  = random_string(pattern)
          expect(string).not_to match(regexp_pattern(:falsey_pattern))
        end
      end
    end
  end
end
