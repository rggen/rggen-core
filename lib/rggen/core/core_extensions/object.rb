# frozen_string_literal: true

class Object
  def export_instance_variable(variable, to)
    instance_variable_defined?(variable) &&
      instance_variable_get(variable)
        .then { |v| block_given? ? yield(v) : v }
        .then { |v| to.instance_variable_set(variable, v) }
  end

  def singleton_exec(...)
    singleton_class.class_exec(...)
  end
end
