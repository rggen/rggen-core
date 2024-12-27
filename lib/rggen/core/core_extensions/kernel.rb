# frozen_string_literal: true

module Kernel
  alias_method :__orignal_Integer, :Integer

  def Integer(arg, base = 0, exception: true)
    arg = arg.__getobj__ if arg.is_a?(::Delegator)
    __orignal_Integer(arg, base, exception:)
  end

  module_function :__orignal_Integer
  module_function :Integer
end
