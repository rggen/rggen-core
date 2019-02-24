if RUBY_VERSION < '2.4'
  casecmp = Module.new do
    def casecmp?(other)
      casecmp(other).zero?
    end
  end

  String.send(:include, casecmp)
  Symbol.send(:include, casecmp)
end
