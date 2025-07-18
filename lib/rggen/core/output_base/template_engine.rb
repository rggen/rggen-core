# frozen_string_literal: true

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
          render(context, template(path))
        end

        private

        def template(path)
          @templates ||= Hash.new { |h, k| h[k] = parse_template(k) }
          @templates[path]
        end
      end
    end
  end
end
