class Object
  def export_instance_variable(variable, to)
    return unless instance_variable_defined?(variable)
    v = instance_variable_get(variable)
    v = yield(v) if block_given?
    to.instance_variable_set(variable, v)
  end
end
