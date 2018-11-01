module Erubi
  class Engine
    def render(context)
      context.instance_eval(src)
    end
  end
end
