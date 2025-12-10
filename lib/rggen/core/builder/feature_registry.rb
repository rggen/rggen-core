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

        def define_feature(name, context, bodies)
          create_new_entry(:general, name, context, bodies)
        end

        def define_simple_feature(name, context, bodies)
          create_new_entry(:simple, name, context, bodies)
        end

        def define_list_feature(list_name, context, bodies)
          create_new_entry(:list, list_name, context, bodies)
        end

        def define_list_item_feature(list_name, feature_name, context, bodies)
          list_item_entry(list_name).define_feature(feature_name, context, bodies)
        end

        def modify_feature(name, bodies)
          modify_entry(:general, name, bodies)
        end

        def modify_simple_feature(name, bodies)
          modify_entry(:simple, name, bodies)
        end

        def modify_list_feature(list_name, bodies)
          modify_entry(:list, list_name, bodies)
        end

        def modify_list_item_feature(list_name, feature_name, bodies)
          list_item_entry(list_name).modify_feature(feature_name, bodies)
        end

        def enable(list_name = nil, feature_names)
          Array(list_name || feature_names)
            .each { |name| @enabled_features[name] ||= [] }

          return unless list_name

          @enabled_features[list_name].merge!(Array(feature_names))
        end

        def enable_all
          disable_all
          @feature_entries.each do |name, entry|
            if entry.match_entry_type?(:list)
              enable(name, entry.features)
            else
              enable(name)
            end
          end
        end

        def disable_all
          @enabled_features.clear
        end

        def delete(list_name = nil, feature_names)
          if list_name
            @feature_entries[list_name]&.delete(feature_names)
          else
            Array(feature_names).each(&@feature_entries.method(:delete))
          end
        end

        def delete_all
          @feature_entries.clear
          @enabled_features.clear
        end

        def feature?(list_name = nil, feature_name)
          if list_name
            list_feature?(list_name, feature_name)
          else
            @feature_entries.key?(feature_name)
          end
        end

        def enabled_features(list_name = nil)
          if !list_name
            @enabled_features.keys.select { |name| feature?(name) }
          elsif enabled_list?(list_name)
            @enabled_features[list_name] & @feature_entries[list_name].features
          end
        end

        def build_factories
          @feature_entries
            .slice(*@enabled_features.keys)
            .transform_values(&method(:build_factory))
        end

        private

        FEATURE_ENTRIES = {
          general: GeneralFeatureEntry,
          simple: SimpleFeatureEntry,
          list: ListFeatureEntry
        }.freeze

        def create_new_entry(type, name, context, bodies)
          entry = FEATURE_ENTRIES[type].new(self, name)
          entry.setup(@base_feature, @factory, context)
          entry.eval_bodies(bodies)
          @feature_entries[name] = entry
        end

        def modify_entry(type, name, bodies)
          entry = @feature_entries[name]
          entry&.match_entry_type?(type) ||
            (raise BuilderError.new("unknown feature: #{name}"))
          entry.eval_bodies(bodies)
        end

        def list_item_entry(list_name)
          entry = @feature_entries[list_name]
          return entry if entry&.match_entry_type?(:list)

          raise BuilderError.new("unknown feature: #{list_name}")
        end

        def list_feature?(list_name, feature_name)
          entry = @feature_entries[list_name]
          return false unless entry

          entry.match_entry_type?(:list) && entry.feature?(feature_name)
        end

        def enabled_list?(name)
          @feature_entries[name]&.match_entry_type?(:list) && @enabled_features.key?(name)
        end

        def build_factory(entry)
          entry.build_factory(@enabled_features[entry.name])
        end
      end
    end
  end
end
