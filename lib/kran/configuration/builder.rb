module Kran
  class Configuration
    class Builder < Section
      def arch
        Array(optional("arch"))
      end

      def remote
        optional("remote")
      end

      def context
        optional("context", ".")
      end
    end
  end
end
