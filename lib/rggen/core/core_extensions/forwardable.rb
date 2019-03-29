# frozen_string_literal: true

module Forwardable
  def delegate_to_class(method_or_methods)
    Array(method_or_methods)
      .each { |m| def_instance_delegator(:'self.class', m) }
  end
end

if ['2.3.1', '2.3.2', '2.3.3'].include?(RUBY_VERSION)
  require_relative 'forwardable_workaround'
end
