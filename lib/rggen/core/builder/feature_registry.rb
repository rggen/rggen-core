# frozen_string_literal: true

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

        def define_simple_feature(name, context = nil, &body)
          create_new_entry(:simple, name, context, &body)
        end

        def define_list_feature(list_name, context = nil, &body)
          create_new_entry(:list, list_name, context, &body)
        end

        def define_list_item_feature(list_name, feature_name, context = nil, &body)
          entry = @feature_entries[list_name]
          entry&.match_entry_type?(:list) ||
            (raise BuilderError.new("unknown list feature: #{list_name}"))
          entry.define_feature(feature_name, context, &body)
        end

        def enable(feature_or_list_names, feature_names = nil)
          if feature_names
            list_name = feature_or_list_names
            (@enabled_features[list_name] ||= []).merge!(Array(feature_names))
          else
            Array(feature_or_list_names).each do |name|
              @enabled_features.key?(name) || (@enabled_features[name] = nil)
            end
          end
        end

        def enable_all
          @enabled_features.clear
        end

        def delete(feature_or_list_names = nil, feature_names = nil)
          if feature_names
            @feature_entries[feature_or_list_names]&.delete(feature_names)
          elsif feature_or_list_names
            Array(feature_or_list_names).each(&@feature_entries.method(:delete))
          else
            @feature_entries.clear
          end
        end

        def simple_feature?(feature_name)
          @feature_entries[feature_name]&.match_entry_type?(:simple) || false
        end

        def list_feature?(list_name, feature_name = nil)
          return false unless @feature_entries[list_name]&.match_entry_type?(:list)
          return true unless feature_name
          @feature_entries[list_name].feature?(feature_name)
        end

        def feature?(feature_or_list_name, feature_name = nil)
          if feature_name
            list_feature?(feature_or_list_name, feature_name)
          else
            simple_feature?(feature_or_list_name) || list_feature?(feature_or_list_name)
          end
        end

        def build_factories
          target_features =
            (@enabled_features.empty? && @feature_entries || @enabled_features).keys
          @feature_entries
            .slice(*target_features)
            .transform_values(&method(:build_factory))
        end

        private

        FEATURE_ENTRIES = {
          simple: SimpleFeatureEntry, list: ListFeatureEntry
        }.freeze

        def create_new_entry(type, name, context, &body)
          entry = FEATURE_ENTRIES[type].new(self, name)
          entry.setup(@base_feature, @factory, context, &body)
          @feature_entries[name] = entry
        end

        def build_factory(entry)
          entry.build_factory(@enabled_features[entry.name])
        end
      end
    end
  end
end
