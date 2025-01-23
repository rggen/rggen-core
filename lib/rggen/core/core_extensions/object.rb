# frozen_string_literal: true

class Object
  def singleton_exec(...)
    singleton_class.class_exec(...)
  end
end
