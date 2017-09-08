require 'docile'

require_relative 'core/version'

require_relative 'core/facets'
require_relative 'core/core_extensions/object'
require_relative 'core/core_extensions/forwardable'
require_relative 'core/core_extensions/module'

require_relative 'core/exceptions'

require_relative 'core/base/internal_struct'
require_relative 'core/base/component'
require_relative 'core/base/component_factory'
require_relative 'core/base/item'
require_relative 'core/base/item_factory'
require_relative 'core/base/hierarchical_accessors'
require_relative 'core/base/hierarchical_item_accessors'

require_relative 'core/input_base/input_value'
require_relative 'core/input_base/input_data'
require_relative 'core/input_base/loader'
require_relative 'core/input_base/input_matcher'
require_relative 'core/input_base/component'
require_relative 'core/input_base/component_factory'
require_relative 'core/input_base/item'
require_relative 'core/input_base/item_factory'

require_relative 'core/configuration/error'
require_relative 'core/configuration/component'
require_relative 'core/configuration/item'
require_relative 'core/configuration/loader'
require_relative 'core/configuration/ruby_loader'
require_relative 'core/configuration/hash_loader'
