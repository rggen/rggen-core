module RgGen
  module Core
    module OutputBase
      class Item < Base::Item
        CODE_GENRATION_PHASES = [:pre, :main, :post].freeze

        class << self
          attr_reader :builders

          def build(&body)
            @builders ||= []
            @builders << body
          end

          def code_generators
            @code_generators ||= {}
          end

          CODE_GENRATION_PHASES.each do |phase|
            define_method("#{phase}_code") do |kind, options = {}, &body|
              code_generators[phase] ||= CodeGenerator.new
              block =
                if from_template?(options)
                  caller_location = caller_locations(1, 1).first
                  template_path = options[:template_path]
                  -> { process_template(template_path, caller_location) }
                else
                  body
                end
              code_generators[phase].register(kind, block)
            end
          end

          def template_engine(engine = nil)
            @template_engine = engine.instance if engine
            @template_engine
          end

          attr_reader :file_writer

          def write_file(file_name_pattern, &body)
            @file_writer = FileWriter.new(file_name_pattern, body)
          end

          def exported_methods
            @exported_methods ||= []
          end

          def export(*methods)
            exported_methods.concat(
              methods.reject(&exported_methods.method(:include?))
            )
          end

          private

          def inherited(subclass)
            export_instance_variable(:@builders, subclass, &:dup)
            export_instance_variable(:@template_engine, subclass)
            export_instance_variable(:@file_writer, subclass)
            export_instance_variable(:@exported_methods, subclass, &:dup)
            copy_code_generators(subclass)
          end

          def copy_code_generators(subclass)
            return unless @code_generators
            return if @code_generators.empty?
            copied_generators = @code_generators.flat_map do |phase, generator|
              [phase, generator.copy]
            end
            subclass.instance_variable_set(
              :@code_generators, Hash[*copied_generators]
            )
          end

          def from_template?(options)
            if options.key?(:from_template)
              options[:from_template]
            else
              options.key?(:template_path)
            end
          end
        end

        def build
          builders = self.class.builders
          builders && builders.each { |body| instance_exec(&body) }
        end

        CODE_GENRATION_PHASES.each do |phase|
          define_method("generate_#{phase}_code") do |kind, code = nil|
            generator = self.class.code_generators[phase]
            (generator && generator.generate(self, kind, code)) || code
          end
        end

        def write_file(directory = nil)
          file_writer = self.class.file_writer
          file_writer && file_writer.write_file(self, directory)
        end

        def exported_methods
          self.class.exported_methods
        end

        private

        def process_template(path = nil, caller_location = nil)
          caller_location ||= caller_locations(1, 1).first
          template_engine = self.class.template_engine
          template_engine.process_template(self, path, caller_location)
        end
      end
    end
  end
end