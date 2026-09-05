module Kran
  class Configuration
    class App < Section
      def selector
        required("selector")
      end

      def container
        optional("container")
      end
    end
  end
end
