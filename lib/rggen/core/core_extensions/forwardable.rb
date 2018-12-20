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

  if ['2.3.1', '2.3.2', '2.3.3'].include?(RUBY_VERSION)
    # https://bugs.ruby-lang.org/issues/12478
    def def_single_delegator(accessor, method, ali = method)
      accessor = accessor.to_s
      if method_defined?(accessor) || private_method_defined?(accessor)
        accessor = "#{accessor}()"
      end if self.class === Module

      line_no = __LINE__; str = %{
        def #{ali}(*args, &block)
          begin
            #{accessor}.__send__(:#{method}, *args, &block)
          rescue ::Exception
            $@.delete_if{|s| ::Forwardable::FILE_REGEXP =~ s} unless ::Forwardable::debug
            ::Kernel::raise
          end
        end
      }

      instance_eval(str, __FILE__, line_no)
    end
  end

  alias_method :object_delegator, :def_object_delegator
  alias_method :object_delegators, :def_object_delegators
end
