module Kran
  class Configuration
    class Kubernetes < Section
      def kubeconfig
        path = optional("kubeconfig")
        path && File.expand_path(path)
      end

      def context
        required("context")
      end

      def namespace
        required("namespace")
      end
    end
  end
end
