# frozen_string_literal: true

module RgGen
  module Core
    module OutputBase
      class ERBEngine < TemplateEngine
        def file_extension
          :erb
        end

        def parse_template(path)
          Erubi::Engine.new(File.binread(path), filename: path)
        end

        def render(context, template)
          context.instance_eval(template.src, template.filename, 1)
        end
      end
    end
  end
end
