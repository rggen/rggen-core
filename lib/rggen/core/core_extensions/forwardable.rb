require 'forwardable'

module Forwardable
  def def_class_delegator(method, ali = method)
    def_instance_delegator(:'self.class', method, ali)
  end

  def def_class_delegators(*methods)
    def_instance_delegators(:'self.class', *methods)
  end

  alias_method :class_delegator, :def_class_delegator
  alias_method :class_delegators, :def_class_delegators
end

module SingleForwardable
  def def_object_delegator(target, method, ali = method)
    define_singleton_method(ali) do |*args, &block|
      target.__send__(method, *args, &block)
    end
  end

  def def_object_delegators(target, *methods)
    methods.each { |m| def_object_delegator(target, m) }
  end

  alias_method :object_delegator, :def_object_delegator
  alias_method :object_delegators, :def_object_delegators
end
