module RgGen
  module Core
    module Builder
      class FeatureRegistry
        def initialize(base_feature, factory)
          @base_feature = base_feature
          @factory = factory
          @feature_entries = {}
          @enabled_features = {}
        end

        def define_simple_feature(context, name, &body)
          create_new_entry(:simple, name, context, body)
        end

        def define_list_feature(context, list_name, feature_name = nil, &body)
          if feature_name
            entry = @feature_entries[list_name]
            entry&.match_entry_type?(:list) || (
              raise BuilderError.new("unknown list feature: #{list_name}")
            )
            entry.define_feature(feature_name, context, &body)
          else
            create_new_entry(:list, list_name, context, body)
          end
        end

        def defined_feature?(feature_or_list_name, feature_name = nil)
          entry = @feature_entries[feature_or_list_name]
          return false unless entry
          return true unless feature_name
          return false if entry.match_entry_type?(:simple)
          entry.defined_feature?(feature_name)
        end

        def enable(feature_or_list_names, feature_names = nil)
          if feature_names
            list_name = feature_or_list_names
            enable_list_features(list_name, feature_names)
          else
            enable_features(feature_or_list_names)
          end
        end

        def available_feature?(feature_or_list_name, feature_name = nil)
          return false unless defined_feature?(feature_or_list_name, feature_name)
          return false unless @enabled_features.key?(feature_or_list_name)
          return true unless feature_name
          @enabled_features[feature_or_list_name].include?(feature_name)
        end

        def build_factories
          @enabled_features
            .select { |n, _| @feature_entries.key?(n) }
            .map { |n, f| [n, @feature_entries[n].build_factory(f)] }
            .to_h
        end

        private

        FEATURE_ENTRIES = {
          simple: SimpleFeatureEntry, list: ListFeatureEntry
        }.freeze

        def create_new_entry(type, name, context, body)
          entry = FEATURE_ENTRIES[type].new(self, name)
          entry.setup(@base_feature, @factory, context, body)
          @feature_entries[name] = entry
        end

        def enable_features(features)
          Array(features).each do |feaure|
            @enabled_features[feaure] ||= []
          end
        end

        def enable_list_features(list_name, features)
          @enabled_features[list_name]&.merge!(Array(features))
        end
      end
    end
  end
end
