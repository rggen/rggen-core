# frozen_string_literal: true

module RgGen
  module Core
    module OutputBase
      class Feature < Base::Feature
        include Base::FeatureLayerExtension
        include RaiseError

        class << self
          attr_reader :pre_builders
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

          def pre_build(&body)
            @pre_builders ||= []
            @pre_builders << body
          end

          def build(&body)
            @builders ||= []
            @builders << body
          end

          [:pre_code, :main_code, :post_code].each do |phase|
            define_method(phase) do |kind, **options, &body|
              register_code_generator(__method__, kind, **options, &body)
            end
          end

          def register_code_generator(phase, kind, **options, &body)
            block =
              if options[:from_template]
                path = extract_template_path(options)
                location = caller_locations(2, 1).first
                -> { process_template(path, location) }
              else
                body
              end
            (code_generators[phase] ||= CodeGenerator.new)
              .register(kind, &block)
          end

          def extract_template_path(options)
            path = options[:from_template]
            path.equal?(true) ? nil : path
          end

          def write_file(file_name_pattern, &body)
            @file_writer = FileWriter.new(file_name_pattern, &body)
          end

          def export(*methods)
            methods.each do |method|
              exported_methods.include?(method) ||
                (exported_methods << method)
            end
          end
        end

        class << self
          def inherited(subclass)
            super
            export_instance_variable(:@pre_builders, subclass, &:dup)
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
          define_layer_methods
        end

        def pre_build
          helper
            .pre_builders
            &.each { |body| instance_exec(&body) }
        end

        def build
          helper
            .builders
            &.each { |body| instance_exec(&body) }
        end

        def export(*methods)
          methods.each do |method|
            unless exported_methods(:class).include?(method) ||
                   exported_methods(:object).include?(method)
              exported_methods(:object) << method
            end
          end
        end

        def exported_methods(scope)
          if scope == :class
            self.class.exported_methods
          else
            @exported_methods ||= []
          end
        end

        def generate_code(code, phase, kind)
          generator = self.class.code_generators[phase]
          generator&.generate(self, code, kind)
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
