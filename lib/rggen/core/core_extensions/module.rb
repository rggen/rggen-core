# frozen_string_literal: true

class Module
  private

  def attr_private_reader(*name)
    attr_reader(*name).tap { private(*name) }
  end

  def define_private_method(name, body = nil)
    body ||= proc if block_given?
    define_method(name, body).tap { private(name) }
  end

  # workaround for following issue
  # https://github.com/rubyworks/facets/issues/286
  def attr_setter(*args)
    code, made = +'', []
    args.each do |a|
      code << %{
        def #{a}(*args)
          args.size > 0 ? ( @#{a}=args[0] ; self ) : @#{a}
        end
      }
      made << "#{a}".to_sym
    end
    module_eval code
    made
  end
end
