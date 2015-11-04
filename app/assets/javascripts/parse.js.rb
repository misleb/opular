module Op
  class Parse
    def _get
      self
    end

    def proc(expr)
      if expr.is_a?(Proc)
        expr
      elsif expr.is_a?(String)
        compiled = Opal.compile("-> {\n#{expr}\n}")
        `eval(#{compiled})`
      else
        -> {}
      end
    end
  end
end