module Op
  module Directive
    class Base
      attr_reader :restrict, :priority, :terminal, :multi_element
      attr_accessor :name, :__end, :__start

      def initialize
        @restrict = 'EA'
        @name = "Base"
        @priority = 0
      end

      def _get
        self
      end
    end

    class App < Base
      def initialize
        super

        @restrict = 'A'
        @name = "opApp"
      end

      def compile(element)
        puts "Compiling..."
        element.data('hasCompiled', true)
      end
    end
  end
end
