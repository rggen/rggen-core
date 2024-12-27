# frozen_string_literal: true

module RgGen
  module Core
    module Builder
      class FeatureEntryBase
        def initialize(registry, name)
          @registry = registry
          @name = name
        end

        attr_reader :registry
        attr_reader :name

        def modify(&)
          eval_body(&)
        end

        def match_entry_type?(entry_type)
          entry_type == entry_type_name
        end

        def build_factory(targets)
          @factory.new(name) do |f|
            f.target_features(target_features(targets))
            f.target_feature(target_feature)
          end
        end

        private

        def attach_shared_context(context, *targets)
          (context && targets)&.each do |target|
            target.attach_context(context)
          end
        end

        def eval_body(&)
          block_given? && Docile.dsl_eval(self, @name, &)
        end

        def target_features(_tergets)
        end

        def target_feature
        end
      end
    end
  end
end
