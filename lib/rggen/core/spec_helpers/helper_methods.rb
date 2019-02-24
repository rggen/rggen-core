module RgGen
  module Core
    module SpecHelpers
      module HelperMethods
        def random_updown_case(string)
          string
            .chars
            .map { |char| [true, false].sample ? char.swapcase : char }
            .join
        end

        if RUBY_VERSION > '2.5'
          require 'securerandom'
          def random_alphanumeric(length)
            SecureRandom.alphanumeric(length)
          end
        else
          ALPHANUMERICS =
            [('a'..'z'), ('A'..'Z'), ('0'..'9')].flat_map(&:to_a).freeze

          def random_alphanumeric(length)
            Array
              .new(length) { ALPHANUMERICS.sample }
              .join
          end
        end

        def random_string(length, exceptions = nil)
          loop do
            string = random_alphanumeric(length)
            return string if exceptions&.none?(&string.method(:casecmp?))
          end
        end

        def random_file_extensions(max_length: 3, exceptions: nil)
          Array.new(max_length) { |i| random_string(i + 1, exceptions) }
        end
      end
    end
  end
end
