# frozen_string_literal: true

require 'delegate'
require 'docile'
require 'erubi'
require 'fileutils'
require 'forwardable'
require 'optparse'
require 'pathname'
require 'singleton'

autoload :JSON, 'json'
autoload :Psych, 'yaml'
autoload :Tomlrb, 'tomlrb'

require_relative 'core/version'

require_relative 'core/facets'
require_relative 'core/core_extensions/kernel'
require_relative 'core/core_extensions/object'

require_relative 'core/utility/attribute_setter'
require_relative 'core/utility/code_utility/line'
require_relative 'core/utility/code_utility/code_block'
require_relative 'core/utility/code_utility/source_file'
require_relative 'core/utility/code_utility/structure_definition'
require_relative 'core/utility/code_utility'
require_relative 'core/utility/error_utility'
require_relative 'core/utility/regexp_patterns'
require_relative 'core/utility/type_checker'

require_relative 'core/exceptions'

require_relative 'core/base/feature_variable'
require_relative 'core/base/internal_struct'
require_relative 'core/base/shared_context'
require_relative 'core/base/component'
require_relative 'core/base/component_factory'
require_relative 'core/base/component_layer_extension'
require_relative 'core/base/feature'
require_relative 'core/base/feature_factory'
require_relative 'core/base/feature_layer_extension'

require_relative 'core/input_base/error'
require_relative 'core/input_base/input_value'
require_relative 'core/input_base/input_data'
require_relative 'core/input_base/input_value_extractor'
require_relative 'core/input_base/conversion_utility'
require_relative 'core/input_base/loader'
require_relative 'core/input_base/json_loader'
require_relative 'core/input_base/toml_loader'
require_relative 'core/input_base/yaml_loader'
require_relative 'core/input_base/component'
require_relative 'core/input_base/component_factory'
require_relative 'core/input_base/input_matcher'
require_relative 'core/input_base/verifier'
require_relative 'core/input_base/property'
require_relative 'core/input_base/feature'
require_relative 'core/input_base/input_vaue_parser'
require_relative 'core/input_base/option_array_parser'
require_relative 'core/input_base/option_hash_parser'
require_relative 'core/input_base/hash_list_parser'
require_relative 'core/input_base/feature_factory'

require_relative 'core/configuration/input_data'
require_relative 'core/configuration/component'
require_relative 'core/configuration/component_factory'
require_relative 'core/configuration/feature'
require_relative 'core/configuration/feature_factory'
require_relative 'core/configuration/loader'
require_relative 'core/configuration/ruby_loader'
require_relative 'core/configuration/hash_loader'
require_relative 'core/configuration/json_loader'
require_relative 'core/configuration/toml_loader'
require_relative 'core/configuration/yaml_loader'
require_relative 'core/configuration'

require_relative 'core/register_map/input_data'
require_relative 'core/register_map/component'
require_relative 'core/register_map/component_factory'
require_relative 'core/register_map/feature'
require_relative 'core/register_map/feature_factory'
require_relative 'core/register_map/loader'
require_relative 'core/register_map/ruby_loader'
require_relative 'core/register_map/hash_loader'
require_relative 'core/register_map/json_loader'
require_relative 'core/register_map/toml_loader'
require_relative 'core/register_map/yaml_loader'
require_relative 'core/register_map'

require_relative 'core/output_base/template_engine'
require_relative 'core/output_base/erb_engine'
require_relative 'core/output_base/file_writer'
require_relative 'core/output_base/code_generatable'
require_relative 'core/output_base/raise_error'
require_relative 'core/output_base/component'
require_relative 'core/output_base/component_factory'
require_relative 'core/output_base/source_file_component_factory'
require_relative 'core/output_base/document_component_factory'
require_relative 'core/output_base/feature'
require_relative 'core/output_base/feature_factory'

require_relative 'core/builder/component_entry'
require_relative 'core/builder/component_registry'
require_relative 'core/builder/loader_registry'
require_relative 'core/builder/input_component_registry'
require_relative 'core/builder/output_component_registry'
require_relative 'core/builder/feature_entry_base'
require_relative 'core/builder/general_feature_entry'
require_relative 'core/builder/simple_feature_entry'
require_relative 'core/builder/list_feature_entry'
require_relative 'core/builder/feature_registry'
require_relative 'core/builder/layer'
require_relative 'core/builder/plugin_spec'
require_relative 'core/builder/plugin_manager'
require_relative 'core/builder/builder'
require_relative 'core/builder'

require_relative 'core/printers'
require_relative 'core/options'
require_relative 'core/dsl'
require_relative 'core/generator'
require_relative 'core/cli'
