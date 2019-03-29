# frozen_string_literal: true

module SingleForwardable
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
