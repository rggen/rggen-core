# frozen_string_literal: true

module RgGen
  module Core
    module OutputBase
      module CodeGeneratable
        CODE_PHASES = [
          :pre_code, :main_code, :post_code
        ].freeze

        VARIABLE_NAMES =
          CODE_PHASES
            .to_h { |phase| [phase, :"@#{phase}_blocks"] }
            .freeze

        module Extension
          private

          CODE_PHASES.each do |phase|
            define_method(phase) do |kind, **options, &body|
              regiter_code_block(__method__, kind, **options, &body)
            end
          end

          def regiter_code_block(phase, kind, **options, &body)
            block =
              if options[:from_template]
                path = extract_template_path(options)
                location = caller_locations(2, 1).first
                -> { process_template(path, location) }
              else
                body
              end
            return unless block

            variable_name = VARIABLE_NAMES[phase]
            feature_hash_array_variable_push(variable_name, kind, block)
          end

          def extract_template_path(options)
            path = options[:from_template]
            path.equal?(true) ? nil : path
          end

          def template_engine(engine)
            @template_engine = engine.instance
          end
        end

        def self.included(klass)
          klass.extend(Extension)
        end

        def generate_code(code, phase, kind)
          blocks = feature_hash_array_variable_get(VARIABLE_NAMES[phase])
          return unless blocks

          blocks[kind]&.each do |block|
            if block.arity.zero?
              code << instance_exec(&block)
            else
              instance_exec(code, &block)
            end
          end
        end

        private

        def process_template(path = nil, caller_location = nil)
          caller_location ||= caller_locations(1, 1).first
          template_engine = feaure_scala_variable_get(:@template_engine)
          template_engine.process_template(self, path, caller_location)
        end
      end
    end
  end
end
