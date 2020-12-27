# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RgGen::Core::Utility::ErrorUtility do
  let(:utility) { RgGen::Core::Utility::ErrorUtility }

  describe '#compose_error_message' do
    let(:error_without_verbose_info) do
      begin
        1 / 0
      rescue StandardError => e
        e
      end
    end

    let(:error_with_verbose_info) do
      foo = 1
      bar = 2
      begin
        baz
      rescue NameError => e
        def e.verbose_info
          ['defined local variables:', *local_variables].join("\n")
        end
        e
      end
    end

    let(:base_message) do
      [
        "[#{error_without_verbose_info.class}] #{error_without_verbose_info}",
        "[#{error_with_verbose_info.class}] #{error_with_verbose_info}"
      ]
    end

    context 'verobse/backtraceともにfalseが指定されている場合' do
      it 'エラーメッセージのみ表示する' do
        message = utility.compose_error_message(error_without_verbose_info, false, false)
        expect(message).to eq base_message[0]

        message = utility.compose_error_message(error_with_verbose_info, false, false)
        expect(message).to eq base_message[1]
      end
    end

    context 'verboseにtrueが設定され、例外が#verbose_infoを持たない場合' do
      it '詳細情報は表示しない' do
        message = utility.compose_error_message(error_without_verbose_info, true, false)
        expect(message).to eq base_message[0]
      end
    end

    context 'verboseにtrueが設定され、例外が#verbose_infoを持つ場合' do
      it '詳細情報を表示する' do
        message = utility.compose_error_message(error_with_verbose_info, true, false)
        expect(message).to eq [
          base_message[1],
          'verbose information:',
          '    defined local variables:',
          *error_with_verbose_info.local_variables.map { |v| "    #{v}" }
        ].join("\n")
      end
    end

    context 'backtraceにtrueが指定されている場合' do
      it 'バックトレースを表示する' do
        message = utility.compose_error_message(error_without_verbose_info, false, true)
        expect(message).to eq [
          base_message[0],
          'backtrace:',
          *error_without_verbose_info.backtrace.map { |trace| "    #{trace}" }
        ].join("\n")

        message = utility.compose_error_message(error_with_verbose_info, false, true)
        expect(message).to eq [
          base_message[1],
          'backtrace:',
          *error_with_verbose_info.backtrace.map { |trace| "    #{trace}" }
        ].join("\n")
      end
    end
  end
end
