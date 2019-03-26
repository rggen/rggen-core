# frozen_string_literal: true

module RgGen
  module Core
    module OutputBase
      class Feature < Base::Feature
        include Base::HierarchicalFeatureAccessors

        class << self
          attr_reader :builders

          def code_generators
            @code_generators ||= {}
          end

          def template_engine(engine = nil)
            @template_engine = engine.instance if engine
            @template_engine
          end

          attr_reader :file_writer

          def exported_methods
            @exported_methods ||= []
          end

          private

          def build(&body)
            @builders ||= []
            @builders << body
          end

          def register_code_generation(kind, **options, &body)
            block =
              if options[:from_template]
                caller_location = caller_locations(1, 1).first
                template_path = extract_template_path(options)
                -> { process_template(template_path, caller_location) }
              else
                body
              end
            code_generators[__callee__] ||= CodeGenerator.new
            code_generators[__callee__].register(kind, block)
          end

          alias_method :pre_code, :register_code_generation
          alias_method :main_code, :register_code_generation
          alias_method :post_code, :register_code_generation

          undef_method :register_code_generation

          def extract_template_path(options)
            path = options[:from_template]
            path.equal?(true) ? nil : path
          end

          def write_file(file_name_pattern, &body)
            @file_writer = FileWriter.new(file_name_pattern, body)
          end

          def export(*methods)
            exported_methods.concat(
              methods.reject(&exported_methods.method(:include?))
            )
          end
        end

        class << self
          def inherited(subclass)
            export_instance_variable(:@builders, subclass, &:dup)
            export_instance_variable(:@template_engine, subclass)
            export_instance_variable(:@file_writer, subclass)
            export_instance_variable(:@exported_methods, subclass, &:dup)
            copy_code_generators(subclass)
          end

          def copy_code_generators(subclass)
            @code_generators&.each do |phase, generator|
              subclass.code_generators[phase] = generator.copy
            end
          end
        end

        def post_initialize
          define_hierarchical_accessors
        end

        def build
          builders = self.class.builders
          builders&.each { |body| instance_exec(&body) }
        end

        def export(*methods)
          exported_methods.concat(
            methods.reject(&exported_methods.method(:include?))
          )
        end

        def exported_methods
          @exported_methods ||= Array.new(self.class.exported_methods)
        end

        def generate_code(phase, kind, code = nil)
          generator = self.class.code_generators[phase]
          (generator&.generate(self, kind, code)) || code
        end

        def write_file(directory = nil)
          file_writer = self.class.file_writer
          file_writer&.write_file(self, directory)
        end

        private

        def configuration
          component.configuration
        end

        def process_template(path = nil, caller_location = nil)
          caller_location ||= caller_locations(1, 1).first
          template_engine = self.class.template_engine
          template_engine.process_template(self, path, caller_location)
        end
      end
    end
  end
end
