# frozen_string_literal: true

class Object
  def export_instance_variable(variable, to)
    instance_variable_defined?(variable) &&
      instance_variable_get(variable)
        .yield_self { |v| block_given? ? yield(v) : v }
        .yield_self { |v| to.instance_variable_set(variable, v) }
  end

  def singleton_exec(*args, &block)
    singleton_class.class_exec(*args, &block)
  end
end
