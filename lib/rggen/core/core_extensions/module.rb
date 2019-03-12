# frozen_string_literal: true

class Module
  private

  def define_private_method(name, body = nil)
    body ||= proc if block_given?
    define_method(name, body).tap { private(name) }
  end
end
