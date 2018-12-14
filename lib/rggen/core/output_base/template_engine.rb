module RgGen
  module Core
    module OutputBase
      class TemplateEngine
        include Singleton

        def process_template(context, path = nil, caller_location = nil)
          unless path
            caller_location ||= caller_locations(1, 1).first
            path = File.ext(caller_location.path, file_extension.to_s)
          end
          render(context, templates[path])
        end

        private

        def extract_template_path(caller_info)
          File.ext(caller_info.path, file_extension.to_s)
        end

        def templates
          @templates ||= Hash.new do |templates, path|
            templates[path] = parse_template(path)
          end
        end
      end
    end
  end
end
