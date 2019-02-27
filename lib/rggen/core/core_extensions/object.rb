# frozen_string_literal: true

class Object
  def export_instance_variable(variable, to)
    return unless instance_variable_defined?(variable)
    v = instance_variable_get(variable)
    v = yield(v) if block_given?
    to.instance_variable_set(variable, v)
  end

  def singleton_exec(*args, &block)
    singleton_class.class_exec(*args, &block)
  end
end
