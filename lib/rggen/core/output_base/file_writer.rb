# frozen_string_literal: true

module RgGen
  module Core
    module OutputBase
      class FileWriter
        def initialize(pattern, body)
          @pattern = Erubi::Engine.new(pattern)
          @body = body
        end

        def write_file(context, directory = nil)
          path = generate_path(context, directory)
          content = generate_content(context, path)
          create_directory(path)
          File.binwrite(path, content)
        end

        private

        def generate_path(context, directory)
          [
            *Array(directory), context.instance_eval(@pattern.src)
          ].map(&:to_s).reject(&:empty?).to_path
        end

        def generate_content(context, path)
          content = context.create_blank_file(path)
          @body && context.instance_exec(content, &@body)
          content
        end

        def create_directory(path)
          directory = path.dirname
          directory.directory? || directory.mkpath
        end
      end
    end
  end
end
